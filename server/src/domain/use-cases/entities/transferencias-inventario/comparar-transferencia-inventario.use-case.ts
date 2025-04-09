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

interface ProductoComparacion {
  productoId: number
  nombre: string
  cantidadSolicitada: number
  origen: {
    stockActual: number
    stockDespues: number
    stockMinimo: number | null
    stockBajoDespues: boolean
  } | null
  destino: {
    stockActual: number
    stockDespues: number
  }
  procesable: boolean
}

interface CompararTransferenciaResponse {
  sucursalOrigen: {
    id: number
    nombre: string
  }
  sucursalDestino: {
    id: number
    nombre: string
  }
  productos: ProductoComparacion[]
  procesable: boolean
}

interface SucursalesTransferenciaInv {
  sucursalOrigen: {
    id: number
    nombre: string
  }
  sucursalDestino: {
    id: number
    nombre: string
  }
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
    sucursalesTransferenciaInv: SucursalesTransferenciaInv
  ): Promise<CompararTransferenciaResponse> {
    const { sucursalOrigen, sucursalDestino } = sucursalesTransferenciaInv

    const itemsTransferencia = await db
      .select({
        id: itemsTransferenciaInventarioTable.id,
        productoId: itemsTransferenciaInventarioTable.productoId,
        cantidad: itemsTransferenciaInventarioTable.cantidad,
        nombreProducto: productosTable.nombre
      })
      .from(itemsTransferenciaInventarioTable)
      .innerJoin(
        productosTable,
        eq(itemsTransferenciaInventarioTable.productoId, productosTable.id)
      )
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

    const sucursalesIds = [sucursalOrigen.id, sucursalDestino.id]
    const productoIds = itemsTransferencia.map((item) => item.productoId)

    const productos = await db
      .select({
        productoId: productosTable.id,
        nombre: productosTable.nombre,
        stockMinimo: productosTable.stockMinimo,
        id: detallesProductoTable.id,
        stock: detallesProductoTable.stock,
        sucursalId: detallesProductoTable.sucursalId
      })
      .from(productosTable)
      .leftJoin(
        detallesProductoTable,
        eq(productosTable.id, detallesProductoTable.productoId)
      )
      .where(
        and(
          inArray(productosTable.id, productoIds),
          inArray(detallesProductoTable.sucursalId, sucursalesIds)
        )
      )

    const productosOrigen = productos.filter(
      (p) => p.sucursalId === sucursalOrigen.id
    )

    const productosDestino = productos.filter(
      (p) => p.sucursalId === sucursalDestino.id
    )

    const productosOrigenMap = new Map(
      productosOrigen.map((p) => [p.productoId, p])
    )
    const productosDestinoMap = new Map(
      productosDestino.map((p) => [p.productoId, p])
    )

    const comparacionesProductos: ProductoComparacion[] = []
    let validTransference = true

    for (const itemTransferencia of itemsTransferencia) {
      const productoOrigen = productosOrigenMap.get(
        itemTransferencia.productoId
      )

      const productoDestino = productosDestinoMap.get(
        itemTransferencia.productoId
      )

      const stockDestino = productoDestino?.stock ?? 0

      if (productoOrigen?.stock == null) {
        comparacionesProductos.push({
          productoId: itemTransferencia.productoId,
          nombre: itemTransferencia.nombreProducto,
          cantidadSolicitada: itemTransferencia.cantidad,
          procesable: false,
          origen: null,
          destino: {
            stockActual: stockDestino,
            stockDespues: stockDestino + itemTransferencia.cantidad
          }
        })
        validTransference = false

        continue
      }

      const stockOrigenDespues =
        productoOrigen.stock - itemTransferencia.cantidad

      const procesable = stockOrigenDespues >= 0

      const origen = {
        stockActual: productoOrigen.stock,
        stockDespues: productoOrigen.stock - itemTransferencia.cantidad,
        stockMinimo: productoOrigen.stockMinimo,
        stockBajoDespues:
          productoOrigen.stockMinimo != null &&
          stockOrigenDespues < productoOrigen.stockMinimo
      }

      comparacionesProductos.push({
        productoId: itemTransferencia.productoId,
        nombre: itemTransferencia.nombreProducto,
        cantidadSolicitada: itemTransferencia.cantidad,
        origen,
        destino: {
          stockActual: stockDestino,
          stockDespues: stockDestino + itemTransferencia.cantidad
        },
        procesable
      })
    }

    return {
      sucursalOrigen,
      sucursalDestino,
      procesable: validTransference,
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
      .select({
        id: sucursalesTable.id,
        nombre: sucursalesTable.nombre
      })
      .from(sucursalesTable)
      .where(
        eq(sucursalesTable.id, compararTransferenciaInvDto.sucursalOrigenId)
      )

    if (sucursales.length < 1) {
      throw CustomError.badRequest(
        'La sucursal de origen especificada no existe'
      )
    }

    const [sucursalOrigen] = sucursales

    const transferenciasInventario = await db
      .select({
        id: transferenciasInventariosTable.id,
        modificable: transferenciasInventariosTable.modificable,
        sucursalDestino: {
          id: sucursalesTable.id,
          nombre: sucursalesTable.nombre
        },
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
      .innerJoin(
        sucursalesTable,
        eq(transferenciasInventariosTable.sucursalDestinoId, sucursalesTable.id)
      )
      .where(eq(transferenciasInventariosTable.id, numericIdDto.id))

    if (transferenciasInventario.length < 1) {
      throw CustomError.badRequest(
        'La transferencia de inventario que intentó comparar no existe'
      )
    }

    const [transferenciaInventario] = transferenciasInventario
    const { sucursalDestino } = transferenciaInventario

    if (
      transferenciaInventario.codigoEstado !==
      estadosTransferenciasInvCodes.pedido
    ) {
      throw CustomError.badRequest(
        'La transferencia de inventario que intentó comparar ya ha sido atendida'
      )
    }

    if (sucursalDestino.id === compararTransferenciaInvDto.sucursalOrigenId) {
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

    return {
      sucursalOrigen,
      sucursalDestino
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

    const sucursalesTransferenciaInv = await this.validateRelated(
      numericIdDto,
      compararTransferenciaInvDto,
      sucursalId,
      hasPermissionAny
    )

    const result = await this.compararTransferenciaInv(
      numericIdDto,
      sucursalesTransferenciaInv
    )

    return result
  }
}
