import { estadosTransferenciasInvCodes, permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  detallesProductoTable,
  estadosTransferenciasInventarios,
  itemsTransferenciaInventarioTable,
  productosTable,
  sucursalesTable,
  transferenciasInventariosTable
} from '@/db/schema'
import type { CompararTransferenciaInvDto } from '@/domain/dtos/entities/transferencias-inventario/comparar-transferencia-inventario.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq, inArray } from 'drizzle-orm'

interface CompararTransferenciaResponse {
  sucursalOrigen: {
    id: number
    nombre: string
  }
  sucursalDestino: {
    id: number
    nombre: string
  }
  productos: Array<{
    productoId: number
    nombre: string
    stockOrigenActual: number
    stockOrigenResultante: number
    stockDestinoActual: number
    stockMinimo: number | null
    cantidadSolicitada: number
    stockDisponible: boolean
    stockBajoEnOrigen: boolean
  }>
}

export class CompararTransferenciaInventario {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.transferenciasInvs.sendAny
  private readonly permissionRelated =
    permissionCodes.transferenciasInvs.sendRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async compararTransferenciaInv(
    numericIdDto: NumericIdDto,
    compararTransferenciaInvDto: CompararTransferenciaInvDto
  ): Promise<CompararTransferenciaResponse> {
    const transferencias = await db
      .select({
        id: transferenciasInventariosTable.id,
        sucursalDestinoId: transferenciasInventariosTable.sucursalDestinoId
      })
      .from(transferenciasInventariosTable)
      .where(eq(transferenciasInventariosTable.id, numericIdDto.id))

    if (transferencias.length === 0) {
      throw CustomError.badRequest('La transferencia no existe')
    }

    const sucursalesOrigen = await db
      .select({
        id: sucursalesTable.id,
        nombre: sucursalesTable.nombre
      })
      .from(sucursalesTable)
      .where(
        eq(sucursalesTable.id, compararTransferenciaInvDto.sucursalOrigenId)
      )

    if (sucursalesOrigen.length === 0) {
      throw CustomError.badRequest('La sucursal origen no existe')
    }

    const sucursalesDestino = await db
      .select({
        id: sucursalesTable.id,
        nombre: sucursalesTable.nombre
      })
      .from(sucursalesTable)
      .where(eq(sucursalesTable.id, transferencias[0].sucursalDestinoId))

    if (sucursalesDestino.length === 0) {
      throw CustomError.badRequest('La sucursal destino no existe')
    }

    const itemsTransferencia = await db
      .select({
        id: itemsTransferenciaInventarioTable.id,
        productoId: itemsTransferenciaInventarioTable.productoId,
        cantidad: itemsTransferenciaInventarioTable.cantidad
      })
      .from(itemsTransferenciaInventarioTable)
      .where(
        eq(
          itemsTransferenciaInventarioTable.transferenciaInventarioId,
          numericIdDto.id
        )
      )

    if (itemsTransferencia.length < 1) {
      throw CustomError.badRequest(
        'La transferencia de inventario no tiene ningún producto para ser transferido'
      )
    }

    const productoIds = itemsTransferencia.map((item) => item.productoId)

    // Obtener productos en sucursal origen
    const productosOrigen = await db
      .select({
        id: detallesProductoTable.id,
        nombre: productosTable.nombre,
        stock: detallesProductoTable.stock,
        productoId: detallesProductoTable.productoId,
        stockMinimo: productosTable.stockMinimo
      })
      .from(detallesProductoTable)
      .innerJoin(
        productosTable,
        eq(productosTable.id, detallesProductoTable.productoId)
      )
      .where(
        and(
          eq(
            detallesProductoTable.sucursalId,
            compararTransferenciaInvDto.sucursalOrigenId
          ),
          inArray(detallesProductoTable.productoId, productoIds)
        )
      )

    // Obtener productos en sucursal destino
    const productosDestino = await db
      .select({
        id: detallesProductoTable.id,
        stock: detallesProductoTable.stock,
        productoId: detallesProductoTable.productoId
      })
      .from(detallesProductoTable)
      .where(
        and(
          eq(
            detallesProductoTable.sucursalId,
            transferencias[0].sucursalDestinoId
          ),
          inArray(detallesProductoTable.productoId, productoIds)
        )
      )

    const productosOrigenMap = new Map(
      productosOrigen.map((p) => [p.productoId, p])
    )
    const productosDestinoMap = new Map(
      productosDestino.map((p) => [p.productoId, p])
    )
    const comparacionesProductos = []

    for (const itemTransferencia of itemsTransferencia) {
      const productoOrigen = productosOrigenMap.get(
        itemTransferencia.productoId
      )
      const productoDestino = productosDestinoMap.get(
        itemTransferencia.productoId
      )

      if (productoOrigen === undefined) {
        throw CustomError.badRequest(
          `El producto con id ${itemTransferencia.productoId} no existe en la sucursal de origen especificada`
        )
      }

      const stockOrigenResultante =
        productoOrigen.stock - itemTransferencia.cantidad
      const stockBajoEnOrigen =
        productoOrigen.stockMinimo != null &&
        stockOrigenResultante < productoOrigen.stockMinimo

      comparacionesProductos.push({
        productoId: productoOrigen.productoId,
        nombre: productoOrigen.nombre,
        stockOrigenActual: productoOrigen.stock,
        stockOrigenResultante,
        stockDestinoActual: productoDestino?.stock ?? 0,
        stockMinimo: productoOrigen.stockMinimo,
        cantidadSolicitada: itemTransferencia.cantidad,
        stockDisponible: productoOrigen.stock >= itemTransferencia.cantidad,
        stockBajoEnOrigen
      })
    }

    return {
      sucursalOrigen: sucursalesOrigen[0],
      sucursalDestino: sucursalesDestino[0],
      productos: comparacionesProductos
    }
  }

  private async validateRelated(
    numericIdDto: NumericIdDto,
    compararTransferenciaInvDto: CompararTransferenciaInvDto,
    sucursalId: SucursalIdType,
    hasPermissionAny: boolean
  ) {
    const sucursales = await db
      .select({ id: sucursalesTable.id })
      .from(sucursalesTable)
      .where(
        eq(sucursalesTable.id, compararTransferenciaInvDto.sucursalOrigenId)
      )

    if (sucursales.length < 1) {
      throw CustomError.badRequest(
        'La sucursal de origen especificada no existe'
      )
    }

    const transferenciasInventario = await db
      .select({
        id: transferenciasInventariosTable.id,
        modificable: transferenciasInventariosTable.modificable,
        sucursalDestinoId: transferenciasInventariosTable.sucursalDestinoId,
        codigoEstado: estadosTransferenciasInventarios.codigo
      })
      .from(transferenciasInventariosTable)
      .innerJoin(
        estadosTransferenciasInventarios,
        eq(
          transferenciasInventariosTable.estadoTransferenciaId,
          estadosTransferenciasInventarios.id
        )
      )
      .where(eq(transferenciasInventariosTable.id, numericIdDto.id))

    if (transferenciasInventario.length < 1) {
      throw CustomError.badRequest(
        'La transferencia de inventario que intentó comparar no existe'
      )
    }

    const [transferenciaInventario] = transferenciasInventario

    if (
      transferenciaInventario.codigoEstado !==
      estadosTransferenciasInvCodes.pedido
    ) {
      throw CustomError.badRequest(
        'La transferencia de inventario que intentó comparar ya ha sido atendida'
      )
    }

    if (
      transferenciaInventario.sucursalDestinoId ===
      compararTransferenciaInvDto.sucursalOrigenId
    ) {
      throw CustomError.badRequest(
        'La sucursal de origen y de destino no puede ser la misma'
      )
    }

    if (
      sucursalId !== compararTransferenciaInvDto.sucursalOrigenId &&
      !hasPermissionAny
    ) {
      throw CustomError.forbidden()
    }
  }

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny, this.permissionRelated]
    )

    let hasPermissionAny = false
    let hasPermissionRelated = false

    for (const permission of validPermissions) {
      if (permission.codigoPermiso === this.permissionAny) {
        hasPermissionAny = true
      }
      if (permission.codigoPermiso === this.permissionRelated) {
        hasPermissionRelated = true
      }

      if (hasPermissionAny || hasPermissionRelated) {
        return { hasPermissionAny, sucursalId: permission.sucursalId }
      }
    }

    throw CustomError.forbidden()
  }

  async execute(
    numericIdDto: NumericIdDto,
    compararTransferenciaInvDto: CompararTransferenciaInvDto
  ) {
    const { hasPermissionAny, sucursalId } = await this.validatePermissions()

    await this.validateRelated(
      numericIdDto,
      compararTransferenciaInvDto,
      sucursalId,
      hasPermissionAny
    )

    const result = await this.compararTransferenciaInv(
      numericIdDto,
      compararTransferenciaInvDto
    )

    return result
  }
}
