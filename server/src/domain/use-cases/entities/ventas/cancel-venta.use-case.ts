import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  detallesProductoTable,
  detallesVentaTable,
  productosTable,
  ventasTable
} from '@/db/schema'
import type { CancelVentaDto } from '@/domain/dtos/entities/ventas/cancel-venta.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq, inArray, sum } from 'drizzle-orm'

export class CancelVenta {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.ventas.cancelAny
  private readonly permissionRelated = permissionCodes.ventas.cancelRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async cancelVenta(
    numericIdDto: NumericIdDto,
    cancelVentaDto: CancelVentaDto,
    sucursalId: SucursalIdType
  ) {
    const itemsVenta = await db
      .select({
        cantidad: sum(detallesVentaTable.cantidad).mapWith(Number),
        productoId: detallesVentaTable.productoId
      })
      .from(detallesVentaTable)
      .where(eq(detallesVentaTable.ventaId, numericIdDto.id))
      .groupBy(detallesVentaTable.productoId)

    const productoIds = itemsVenta
      .map((item) => item.productoId)
      .filter((item) => item != null)

    if (productoIds.length < 1) {
      const result = await this.updateVenta(
        numericIdDto,
        cancelVentaDto,
        sucursalId
      )

      return result
    }

    const result = await db.transaction(async (tx) => {
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
            eq(detallesProductoTable.sucursalId, sucursalId),
            inArray(detallesProductoTable.productoId, productoIds)
          )
        )

      const productosMap = new Map(productos.map((p) => [p.id, p]))

      for (const itemVenta of itemsVenta) {
        if (itemVenta.productoId == null) {
          continue
        }

        const producto = productosMap.get(itemVenta.productoId)

        if (producto === undefined) {
          continue
        }

        const stockBajo =
          producto.stockMinimo !== null
            ? itemVenta.cantidad < producto.stockMinimo
            : false

        if (producto.detallesProductoId === null) {
          await tx.insert(detallesProductoTable).values({
            precioCompra: '0',
            precioVenta: '0',
            stock: itemVenta.cantidad,
            stockBajo,
            liquidacion: false,
            productoId: itemVenta.productoId,
            sucursalId
          })
        } else {
          await tx
            .update(detallesProductoTable)
            .set({
              stock: itemVenta.cantidad + (producto.stock ?? 0),
              stockBajo
            })
            .where(eq(detallesProductoTable.id, producto.detallesProductoId))
        }
      }

      const ventas = await db
        .update(ventasTable)
        .set({
          cancelada: true,
          motivoAnulado: cancelVentaDto.motivoAnulado
        })
        .where(
          and(
            eq(ventasTable.id, numericIdDto.id),
            eq(ventasTable.sucursalId, sucursalId)
          )
        )
        .returning({ id: ventasTable.id })

      if (ventas.length < 1) {
        throw CustomError.badRequest(
          'Ha ocurrido un error al intentar cancelar la venta (no se encontró)'
        )
      }

      return ventas
    })

    return result
  }

  private async updateVenta(
    numericIdDto: NumericIdDto,
    cancelVentaDto: CancelVentaDto,
    sucursalId: SucursalIdType
  ) {
    const ventas = await db
      .update(ventasTable)
      .set({
        cancelada: true,
        motivoAnulado: cancelVentaDto.motivoAnulado
      })
      .where(
        and(
          eq(ventasTable.id, numericIdDto.id),
          eq(ventasTable.sucursalId, sucursalId)
        )
      )
      .returning({ id: ventasTable.id })

    if (ventas.length < 1) {
      throw CustomError.badRequest(
        'Ha ocurrido un error al intentar cancelar la venta (no se encontró)'
      )
    }

    const [venta] = ventas

    return venta
  }

  private async validateRelated(
    numericIdDto: NumericIdDto,
    sucursalId: SucursalIdType
  ) {
    const ventas = await db
      .select({
        id: ventasTable.id,
        cancelada: ventasTable.cancelada
      })
      .from(ventasTable)
      .where(
        and(
          eq(ventasTable.id, numericIdDto.id),
          eq(ventasTable.sucursalId, sucursalId)
        )
      )

    if (ventas.length < 1) {
      throw CustomError.badRequest('La venta que intentó cancelar no existe')
    }

    const [venta] = ventas

    if (venta.cancelada) {
      throw CustomError.badRequest(
        'Esta venta no se puede cancelar porque ya ha sido cancelada'
      )
    }
  }

  private async validatePermissions(sucursalId: SucursalIdType) {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny, this.permissionRelated]
    )

    let hasPermissionAny = false
    let hasPermissionRelated = false
    let isSameSucursal = false

    for (const permission of validPermissions) {
      if (permission.codigoPermiso === this.permissionAny) {
        hasPermissionAny = true
      }
      if (permission.codigoPermiso === this.permissionRelated) {
        hasPermissionRelated = true
      }
      if (permission.sucursalId === sucursalId) {
        isSameSucursal = true
      }

      if (hasPermissionAny || (hasPermissionRelated && isSameSucursal)) {
        return
      }
    }

    throw CustomError.forbidden()
  }

  async execute(
    numericIdDto: NumericIdDto,
    cancelVentaDto: CancelVentaDto,
    sucursalId: SucursalIdType
  ) {
    await this.validatePermissions(sucursalId)

    await this.validateRelated(numericIdDto, sucursalId)

    const result = await this.cancelVenta(
      numericIdDto,
      cancelVentaDto,
      sucursalId
    )

    return result
  }
}
