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
import { ProductoEntityMapper } from '@/domain/mappers/producto-entity.mapper'
import type { SucursalIdType } from '@/types/schemas'
import { eq, ne } from 'drizzle-orm'

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
      precioCompra: createProductoDto.precioCompra?.toFixed(2),
      precioVenta: createProductoDto.precioVenta?.toFixed(2),
      precioOferta: createProductoDto.precioOferta?.toFixed(2)
    }

    const sucursales = await db
      .select({ id: sucursalesTable.id })
      .from(sucursalesTable)
      .where(ne(sucursalesTable.id, sucursalId))

    try {
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
          .returning()

        const [detallesProducto] = await tx
          .insert(detallesProductoTable)
          .values({
            precioCompra: mappedPrices.precioCompra,
            precioVenta: mappedPrices.precioVenta,
            precioOferta: mappedPrices.precioOferta,
            stock: createProductoDto.stock,
            productoId: producto.id,
            sucursalId
          })
          .returning({
            precioCompra: detallesProductoTable.precioCompra,
            precioVenta: detallesProductoTable.precioVenta,
            precioOferta: detallesProductoTable.precioOferta,
            stock: detallesProductoTable.stock
          })

        const detallesProductosValues = sucursales.map((sucursal) => ({
          precioCompra: null,
          precioVenta: null,
          precioOferta: null,
          stock: 0,
          productoId: producto.id,
          sucursalId: sucursal.id
        }))

        await tx.insert(detallesProductoTable).values(detallesProductosValues)

        return {
          ...producto,
          precioCompra: detallesProducto.precioCompra,
          precioVenta: detallesProducto.precioVenta,
          precioOferta: detallesProducto.precioOferta,
          stock: detallesProducto.stock
        }
      })

      return insertedProductResult
    } catch (error) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar crear el producto'
      )
    }
  }

  private async validateRelacionados(
    createProductoDto: CreateProductoDto,
    sucursalId: SucursalIdType
  ) {
    const results = await db
      .select({
        sucursalId: sucursalesTable.id,
        colorNombre: coloresTable.nombre,
        categoriaNombre: categoriasTable.nombre,
        marcaNombre: marcasTable.nombre
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

    if (result.colorNombre === null) {
      throw CustomError.badRequest('El color que intentó asignar no existe')
    }

    if (result.categoriaNombre === null) {
      throw CustomError.badRequest('La categoría que intentó asignar no existe')
    }

    if (result.marcaNombre === null) {
      throw CustomError.badRequest('La marca que intentó asignar no existe')
    }

    // const productsWithSameSkuNombre = await db
    //   .select({ sku: productosTable.sku })
    //   .from(productosTable)
    //   .where(or(ilike(productosTable.sku, createProductoDto.sku)))

    // if (productsWithSameSkuNombre.length > 0) {
    //   throw CustomError.badRequest(
    //     `Ya existe un producto con ese sku ${createProductoDto.sku}`
    //   )
    // }

    return {
      colorNombre: result.colorNombre,
      categoriaNombre: result.categoriaNombre,
      marcaNombre: result.marcaNombre
    }
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

    const relacionados = await this.validateRelacionados(
      createProductoDto,
      sucursalId
    )

    const producto = await this.createProducto(createProductoDto, sucursalId)

    const mappedProducto = ProductoEntityMapper.fromObject({
      ...producto,
      relacionados
    })

    return mappedProducto
  }
}
