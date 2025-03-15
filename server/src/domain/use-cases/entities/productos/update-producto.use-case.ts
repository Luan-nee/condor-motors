import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { detallesProductoTable, productosTable } from '@/db/schema'
import type { UpdateProductoDto } from '@/domain/dtos/entities/productos/update-producto.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq } from 'drizzle-orm'

export class UpdateProducto {
  private readonly authPayload: AuthPayload
  private readonly permissionUpdateAny = permissionCodes.productos.updateAny
  private readonly permissionUpdateRelated =
    permissionCodes.productos.updateRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async updateProducto(
    numericIdDto: NumericIdDto,
    updateProductoDto: UpdateProductoDto,
    sucursalId: SucursalIdType
  ) {
    const now = new Date()
    const mappedPrices = {
      precioCompra: updateProductoDto.precioCompra?.toFixed(2),
      precioVenta: updateProductoDto.precioVenta?.toFixed(2),
      precioOferta: updateProductoDto.precioOferta?.toFixed(2)
    }

    try {
      await db.transaction(async (tx) => {
        const updatedProductos = await tx
          .update(productosTable)
          .set({
            nombre: updateProductoDto.nombre,
            descripcion: updateProductoDto.descripcion,
            maxDiasSinReabastecer: updateProductoDto.maxDiasSinReabastecer,
            stockMinimo: updateProductoDto.stockMinimo,
            cantidadMinimaDescuento: updateProductoDto.cantidadMinimaDescuento,
            cantidadGratisDescuento: updateProductoDto.cantidadGratisDescuento,
            porcentajeDescuento: updateProductoDto.porcentajeDescuento,
            colorId: updateProductoDto.colorId,
            categoriaId: updateProductoDto.categoriaId,
            marcaId: updateProductoDto.marcaId,
            fechaActualizacion: now
          })
          .where(eq(productosTable.id, numericIdDto.id))
          .returning({ id: productosTable.id })

        const updatedDetallesProducto = await tx
          .update(detallesProductoTable)
          .set({
            precioCompra: mappedPrices.precioCompra,
            precioVenta: mappedPrices.precioVenta,
            precioOferta: mappedPrices.precioOferta,
            fechaActualizacion: now
          })
          .where(
            and(
              eq(detallesProductoTable.sucursalId, sucursalId),
              eq(detallesProductoTable.productoId, numericIdDto.id)
            )
          )
          .returning({ id: detallesProductoTable.id })

        if (updatedDetallesProducto.length < 1 && updatedProductos.length < 1) {
          tx.rollback()
        }
      })

      return numericIdDto
    } catch (error) {
      throw CustomError.badRequest(
        'Ha ocurrido un error al intentar actualizar el producto'
      )
    }
  }

  private async validatePermissions(sucursalId: SucursalIdType) {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionUpdateAny, this.permissionUpdateRelated]
    )

    const hasPermissionAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionUpdateAny
    )

    if (
      !hasPermissionAny &&
      !validPermissions.some(
        (permission) =>
          permission.codigoPermiso === this.permissionUpdateRelated
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
    updateProductoDto: UpdateProductoDto,
    sucursalId: SucursalIdType
  ) {
    await this.validatePermissions(sucursalId)

    const producto = await this.updateProducto(
      numericIdDto,
      updateProductoDto,
      sucursalId
    )

    return producto
  }
}
