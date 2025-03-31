import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  detallesProductoTable,
  productosTable,
  sucursalesTable
} from '@/db/schema'
import type { AddProductoDto } from '@/domain/dtos/entities/productos/add-producto.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq } from 'drizzle-orm'

export class AddProducto {
  private readonly authPayload: AuthPayload
  private readonly permissionCreateAny = permissionCodes.productos.createAny
  private readonly permissionCreateRelated =
    permissionCodes.productos.createRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async addProducto(
    numericIdDto: NumericIdDto,
    addProductoDto: AddProductoDto,
    sucursalId: SucursalIdType
  ) {
    const detallesProductos = await db
      .select({
        id: detallesProductoTable.id
      })
      .from(detallesProductoTable)
      .where(
        and(
          eq(detallesProductoTable.sucursalId, sucursalId),
          eq(detallesProductoTable.productoId, numericIdDto.id)
        )
      )

    if (detallesProductos.length > 0) {
      throw CustomError.badRequest(
        'El producto especificado ya existe en la sucursal especificada'
      )
    }

    const productos = await db
      .select({
        sucursalId: sucursalesTable.id,
        productoId: productosTable.id,
        stockMinimo: productosTable.stockMinimo
      })
      .from(sucursalesTable)
      .leftJoin(productosTable, eq(productosTable.id, numericIdDto.id))
      .where(eq(sucursalesTable.id, sucursalId))

    if (productos.length < 1) {
      throw CustomError.badRequest('La sucursal que intentó asignar no existe')
    }

    const [producto] = productos

    if (producto.productoId === null) {
      throw CustomError.badRequest('El producto que intentó asignar no existe')
    }

    const mappedPrices = {
      precioCompra: addProductoDto.precioCompra.toFixed(2),
      precioVenta: addProductoDto.precioVenta.toFixed(2),
      precioOferta: addProductoDto.precioOferta?.toFixed(2)
    }

    const detalleProductoStockBajo =
      producto.stockMinimo !== null &&
      addProductoDto.stock < producto.stockMinimo

    const insertedDetallesProductos = await db
      .insert(detallesProductoTable)
      .values({
        precioCompra: mappedPrices.precioCompra,
        precioVenta: mappedPrices.precioVenta,
        precioOferta: mappedPrices.precioOferta,
        stock: addProductoDto.stock,
        stockBajo: detalleProductoStockBajo,
        productoId: numericIdDto.id,
        liquidacion: addProductoDto.liquidacion,
        sucursalId
      })
      .returning({
        id: detallesProductoTable.id
      })

    if (insertedDetallesProductos.length < 1) {
      throw CustomError.badRequest(
        'Ha ocurrido un error al intentar crear el producto en su sucursal'
      )
    }

    const [detalleProducto] = insertedDetallesProductos

    return detalleProducto
  }

  private async validatePermissions(sucursalId: SucursalIdType) {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionCreateAny, this.permissionCreateRelated]
    )

    const hasPermissionCreateAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionCreateAny
    )

    if (
      !hasPermissionCreateAny &&
      !validPermissions.some(
        (permission) =>
          permission.codigoPermiso === this.permissionCreateRelated
      )
    ) {
      throw CustomError.forbidden()
    }

    const isSameSucursal = validPermissions.some(
      (permission) => permission.sucursalId === sucursalId
    )

    if (!hasPermissionCreateAny && !isSameSucursal) {
      throw CustomError.forbidden()
    }
  }

  async execute(
    numericIdDto: NumericIdDto,
    addProductoDto: AddProductoDto,
    sucursalId: SucursalIdType
  ) {
    await this.validatePermissions(sucursalId)

    const detalleProducto = await this.addProducto(
      numericIdDto,
      addProductoDto,
      sucursalId
    )

    return detalleProducto
  }
}
