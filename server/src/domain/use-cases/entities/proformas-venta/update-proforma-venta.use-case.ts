import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  detallesProductoTable,
  productosTable,
  proformasVentaTable
} from '@/db/schema'
import type { UpdateProformaVentaDto } from '@/domain/dtos/entities/proformas-venta/update-proforma-venta.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq, or } from 'drizzle-orm'

export class UpdateProformaVenta {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.proformasVenta.updateAny
  private readonly permissionRelated =
    permissionCodes.proformasVenta.updateRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async updateProformaVenta(
    numericIdDto: NumericIdDto,
    sucursalId: SucursalIdType,
    updateProformaVentaDto: UpdateProformaVentaDto,
    detallesProformaVenta?: Array<{
      id: number
      nombre: string
      precioVenta: string
      detallesProductoId: number
      stock: number
    }>
  ) {
    const mappedDetalles = detallesProformaVenta?.map((detalle) => {
      const detalleProforma = updateProformaVentaDto.detalles?.find(
        (item) => item.productoId === detalle.id
      )

      const cantidad = detalleProforma?.cantidad ?? 1
      const precio = parseFloat(detalle.precioVenta)
      const subtotal = parseFloat((cantidad * precio).toFixed(2))

      return {
        productoId: detalle.id,
        nombre: detalle.nombre,
        cantidad,
        precioUnitario: precio,
        subtotal
      }
    })

    const now = new Date()

    const total = mappedDetalles
      ?.reduce((prev, current) => current.subtotal + prev, 0)
      .toFixed(2)

    const results = await db
      .update(proformasVentaTable)
      .set({
        nombre: updateProformaVentaDto.nombre,
        total,
        detalles: mappedDetalles,
        fechaActualizacion: now
      })
      .where(
        and(
          eq(proformasVentaTable.id, numericIdDto.id),
          eq(proformasVentaTable.sucursalId, sucursalId)
        )
      )
      .returning({ id: proformasVentaTable.id })

    if (results.length < 1) {
      throw CustomError.badRequest(
        `No se pudo actualizar la proforma de venta con el id ${numericIdDto.id} (No encontrada)`
      )
    }

    const [proformaVenta] = results

    return proformaVenta
  }

  private async validateRelated(
    updateProformaVentaDto: UpdateProformaVentaDto,
    sucursalId: SucursalIdType
  ) {
    if (
      updateProformaVentaDto.detalles === undefined ||
      updateProformaVentaDto.detalles.length < 1
    ) {
      return
    }

    const productoIds = updateProformaVentaDto.detalles.map(
      (detalle) => detalle.productoId
    )
    const duplicateProductoIds = productoIds.filter(
      (id, index, self) => self.indexOf(id) !== index
    )

    if (duplicateProductoIds.length > 0) {
      throw CustomError.badRequest(
        `Existen productos duplicados en los detalles: ${[...new Set(duplicateProductoIds)].join(', ')}`
      )
    }

    const productosConditonals = updateProformaVentaDto.detalles.map(
      (detalle) => eq(productosTable.id, detalle.productoId)
    )

    const productos = await db
      .select({
        id: productosTable.id,
        nombre: productosTable.nombre,
        precioVenta: detallesProductoTable.precioVenta,
        detallesProductoId: detallesProductoTable.id,
        stock: detallesProductoTable.stock
      })
      .from(productosTable)
      .innerJoin(
        detallesProductoTable,
        and(
          eq(productosTable.id, detallesProductoTable.productoId),
          eq(detallesProductoTable.sucursalId, sucursalId)
        )
      )
      .where(or(...productosConditonals))

    const invalidProducts = updateProformaVentaDto.detalles.filter(
      (detalleProducto) =>
        !productos.some(
          (producto) => detalleProducto.productoId === producto.id
        )
    )

    if (invalidProducts.length > 0) {
      throw CustomError.badRequest(
        `Estos productos no existen en su sucursal: ${invalidProducts.map((prod) => prod.productoId).join(', ')}`
      )
    }

    const invalidStock = updateProformaVentaDto.detalles.filter(
      (detalleProducto) =>
        productos.some((producto) => detalleProducto.cantidad > producto.stock)
    )

    if (invalidStock.length > 0) {
      throw CustomError.badRequest(
        `Estos productos no tienen el stock suficiente: ${invalidStock.map((prod) => prod.productoId).join(', ')}`
      )
    }

    return productos
  }

  private async validatePermissions(sucursalId: SucursalIdType) {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny, this.permissionRelated]
    )

    const hasPermissionAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionAny
    )

    if (
      !hasPermissionAny &&
      !validPermissions.some(
        (permission) => permission.codigoPermiso === this.permissionRelated
      )
    ) {
      throw CustomError.forbidden()
    }

    const isSameSucursal = validPermissions.some(
      (permission) => permission.sucursalId === sucursalId
    )

    if (!hasPermissionAny && !isSameSucursal) {
      throw CustomError.forbidden()
    }
  }

  async execute(
    numericIdDto: NumericIdDto,
    updateProformaVentaDto: UpdateProformaVentaDto,
    sucursalId: SucursalIdType
  ) {
    await this.validatePermissions(sucursalId)

    const detallesProformaVenta = await this.validateRelated(
      updateProformaVentaDto,
      sucursalId
    )

    const proformaVenta = await this.updateProformaVenta(
      numericIdDto,
      sucursalId,
      updateProformaVentaDto,
      detallesProformaVenta
    )

    return proformaVenta
  }
}
