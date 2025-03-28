import { estadosTransferenciasInvCodes, permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  detallesProductoTable,
  estadosTransferenciasInventarios,
  itemsTransferenciaInventarioTable,
  productosTable,
  transferenciasInventariosTable
} from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq, ilike, inArray } from 'drizzle-orm'

export class CancelarTransferenciaInventario {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.transferenciasInvs.cancelAny
  private readonly permissionRelated =
    permissionCodes.transferenciasInvs.cancelRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async cancelarTransferenciaInv(
    numericIdDto: NumericIdDto,
    sucursalOrigenId: SucursalIdType
  ) {
    const now = new Date()

    const [estadoPedido] = await db
      .select({
        id: estadosTransferenciasInventarios.id
      })
      .from(estadosTransferenciasInventarios)
      .where(
        ilike(
          estadosTransferenciasInventarios.codigo,
          estadosTransferenciasInvCodes.pedido
        )
      )

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
        'La transferencia de inventario no tiene ningún producto para ser recibido'
      )
    }

    const productoIds = itemsTransferencia.map((item) => item.productoId)

    const [result] = await db.transaction(async (tx) => {
      const productos = await tx
        .select({
          id: productosTable.id,
          stockMinimo: productosTable.stockMinimo,
          stock: detallesProductoTable.stock,
          detallesProductoId: detallesProductoTable.id
        })
        .from(productosTable)
        .leftJoin(
          detallesProductoTable,
          eq(productosTable.id, detallesProductoTable.productoId)
        )
        .where(
          and(
            eq(detallesProductoTable.sucursalId, sucursalOrigenId),
            inArray(detallesProductoTable.productoId, productoIds)
          )
        )

      const productosMap = new Map(productos.map((p) => [p.id, p]))

      for (const itemTransferencia of itemsTransferencia) {
        const producto = productosMap.get(itemTransferencia.productoId)

        if (producto === undefined) {
          throw CustomError.internalServer()
        }

        const stockBajo =
          producto.stockMinimo !== null
            ? itemTransferencia.cantidad < producto.stockMinimo
            : false

        if (producto.detallesProductoId === null) {
          await tx.insert(detallesProductoTable).values({
            precioCompra: '0',
            precioVenta: '0',
            stock: itemTransferencia.cantidad,
            stockBajo,
            liquidacion: false,
            productoId: itemTransferencia.productoId,
            sucursalId: sucursalOrigenId
          })
        } else {
          await tx
            .update(detallesProductoTable)
            .set({
              stock: itemTransferencia.cantidad + (producto.stock ?? 0),
              stockBajo
            })
            .where(
              and(
                eq(detallesProductoTable.productoId, producto.id),
                eq(detallesProductoTable.sucursalId, sucursalOrigenId)
              )
            )
        }
      }

      const transferenciasInvs = await tx
        .update(transferenciasInventariosTable)
        .set({
          modificable: true,
          estadoTransferenciaId: estadoPedido.id,
          sucursalOrigenId: null,
          salidaOrigen: null,
          llegadaDestino: null,
          fechaActualizacion: now
        })
        .where(eq(transferenciasInventariosTable.id, numericIdDto.id))
        .returning({
          id: transferenciasInventariosTable.id,
          sucursalOrigenId: transferenciasInventariosTable.sucursalOrigenId,
          sucursalDestinoId: transferenciasInventariosTable.sucursalDestinoId
        })

      if (transferenciasInvs.length < 1) {
        throw CustomError.internalServer(
          'Ha ocurrido un error al intentar cancelar la transferencia de inventario'
        )
      }

      return transferenciasInvs
    })

    return result
  }

  private async validateRelated(
    numericIdDto: NumericIdDto,
    sucursalId: SucursalIdType,
    hasPermissionAny: boolean
  ) {
    const transferenciasInventario = await db
      .select({
        id: transferenciasInventariosTable.id,
        sucursalOrigenId: transferenciasInventariosTable.sucursalOrigenId,
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
        'La transferencia de inventario que intentó cancelar no existe'
      )
    }

    const [transferenciaInventario] = transferenciasInventario

    if (
      transferenciaInventario.codigoEstado !==
        estadosTransferenciasInvCodes.enviado ||
      transferenciaInventario.sucursalOrigenId === null
    ) {
      throw CustomError.badRequest(
        'La transferencia de inventario que intentó recibir aún no se puede cancelar porque ya ha sido completada o aún no ha sido enviada'
      )
    }

    if (
      sucursalId !== transferenciaInventario.sucursalOrigenId &&
      !hasPermissionAny
    ) {
      throw CustomError.forbidden()
    }

    return { sucursalOrigenId: transferenciaInventario.sucursalOrigenId }
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

  async execute(numericIdDto: NumericIdDto) {
    const { hasPermissionAny, sucursalId } = await this.validatePermissions()

    const { sucursalOrigenId } = await this.validateRelated(
      numericIdDto,
      sucursalId,
      hasPermissionAny
    )

    const result = await this.cancelarTransferenciaInv(
      numericIdDto,
      sucursalOrigenId
    )

    return result
  }
}
