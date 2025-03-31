import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  categoriasTable,
  coloresTable,
  detallesProductoTable,
  marcasTable,
  productosTable,
  sucursalesTable
} from '@/db/schema'
import type { CreateProductoDto } from '@/domain/dtos/entities/productos/create-producto.dto'
import type { SucursalIdType } from '@/types/schemas'
import { eq } from 'drizzle-orm'

export class CreateProducto {
  private readonly authPayload: AuthPayload
  private readonly permissionCreateAny = permissionCodes.productos.createAny
  private readonly permissionCreateRelated =
    permissionCodes.productos.createRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async createProducto(
    createProductoDto: CreateProductoDto,
    sucursalId: SucursalIdType
  ) {
    const mappedPrices = {
      precioCompra: createProductoDto.precioCompra.toFixed(2),
      precioVenta: createProductoDto.precioVenta.toFixed(2),
      precioOferta: createProductoDto.precioOferta?.toFixed(2)
    }

    const detalleProductoStockBajo =
      createProductoDto.stockMinimo != null &&
      createProductoDto.stock < createProductoDto.stockMinimo

    const insertedProductResult = await db.transaction(async (tx) => {
      const [producto] = await tx
        .insert(productosTable)
        .values({
          nombre: createProductoDto.nombre,
          descripcion: createProductoDto.descripcion,
          maxDiasSinReabastecer: createProductoDto.maxDiasSinReabastecer,
          stockMinimo: createProductoDto.stockMinimo,
          cantidadMinimaDescuento: createProductoDto.cantidadMinimaDescuento,
          cantidadGratisDescuento: createProductoDto.cantidadGratisDescuento,
          porcentajeDescuento: createProductoDto.porcentajeDescuento,
          colorId: createProductoDto.colorId,
          categoriaId: createProductoDto.categoriaId,
          marcaId: createProductoDto.marcaId
        })
        .returning({
          id: productosTable.id
        })

      await tx
        .insert(detallesProductoTable)
        .values({
          precioCompra: mappedPrices.precioCompra,
          precioVenta: mappedPrices.precioVenta,
          precioOferta: mappedPrices.precioOferta,
          stock: createProductoDto.stock,
          stockBajo: detalleProductoStockBajo,
          productoId: producto.id,
          liquidacion: createProductoDto.liquidacion,
          sucursalId
        })
        .returning({
          id: detallesProductoTable.id
        })

      return producto
    })

    return insertedProductResult
  }

  private async validateRelacionados(
    createProductoDto: CreateProductoDto,
    sucursalId: SucursalIdType
  ) {
    const results = await db
      .select({
        sucursalId: sucursalesTable.id,
        color: coloresTable.nombre,
        categoria: categoriasTable.nombre,
        marca: marcasTable.nombre
      })
      .from(sucursalesTable)
      .leftJoin(coloresTable, eq(coloresTable.id, createProductoDto.colorId))
      .leftJoin(
        categoriasTable,
        eq(categoriasTable.id, createProductoDto.categoriaId)
      )
      .leftJoin(marcasTable, eq(marcasTable.id, createProductoDto.marcaId))
      .where(eq(sucursalesTable.id, sucursalId))

    if (results.length < 1) {
      throw CustomError.badRequest('La sucursal que intentó asignar no existe')
    }

    const [result] = results

    if (result.color === null) {
      throw CustomError.badRequest('El color que intentó asignar no existe')
    }

    if (result.categoria === null) {
      throw CustomError.badRequest('La categoría que intentó asignar no existe')
    }

    if (result.marca === null) {
      throw CustomError.badRequest('La marca que intentó asignar no existe')
    }

    // return {
    //   color: result.color,
    //   categoria: result.categoria,
    //   marca: result.marca
    // }
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
    createProductoDto: CreateProductoDto,
    sucursalId: SucursalIdType
  ) {
    await this.validatePermissions(sucursalId)

    await this.validateRelacionados(createProductoDto, sucursalId)

    const producto = await this.createProducto(createProductoDto, sucursalId)

    return producto
  }
}
