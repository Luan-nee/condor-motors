import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  categoriasTable,
  inventariosTable,
  marcasTable,
  preciosProductosTable,
  productosTable,
  sucursalesInventariosTable,
  sucursalesTable,
  unidadesTable
} from '@/db/schema'
import type { CreateProductoDto } from '@/domain/dtos/entities/productos/create-producto.dto'
import { ProductoEntityMapper } from '@/domain/mappers/producto-entity.mapper'
import { eq, ilike, or } from 'drizzle-orm'

export class CreateProducto {
  private readonly authPayload: AuthPayload
  private readonly permissionCreateAny = permissionCodes.productos.createAny

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async createProducto(createProductoDto: CreateProductoDto) {
    const mappedPrices = {
      precioBase: createProductoDto.precioBase?.toFixed(2),
      precioMayorista: createProductoDto.precioMayorista?.toFixed(2),
      precioOferta: createProductoDto.precioOferta?.toFixed(2)
    }

    try {
      const insertedProductResult = await db.transaction(async (tx) => {
        const [producto] = await tx
          .insert(productosTable)
          .values({
            sku: createProductoDto.sku,
            nombre: createProductoDto.nombre,
            descripcion: createProductoDto.descripcion,
            maxDiasSinReabastecer: createProductoDto.maxDiasSinReabastecer,
            unidadId: createProductoDto.unidadId,
            categoriaId: createProductoDto.categoriaId,
            marcaId: createProductoDto.marcaId
          })
          .returning()

        const [preciosProducto] = await tx
          .insert(preciosProductosTable)
          .values({
            precioBase: mappedPrices.precioBase,
            precioMayorista: mappedPrices.precioMayorista,
            precioOferta: mappedPrices.precioOferta,
            productoId: producto.id,
            sucursalId: createProductoDto.sucursalId
          })
          .returning({
            precioBase: preciosProductosTable.precioBase,
            precioMayorista: preciosProductosTable.precioMayorista,
            precioOferta: preciosProductosTable.precioOferta
          })

        const [inventarioProducto] = await tx
          .insert(inventariosTable)
          .values({
            stock: createProductoDto.stock,
            productoId: producto.id
          })
          .returning({
            id: inventariosTable.id,
            stock: inventariosTable.stock
          })

        await tx.insert(sucursalesInventariosTable).values({
          inventarioId: inventarioProducto.id,
          sucursalId: createProductoDto.sucursalId
        })

        return {
          ...producto,
          precioBase: preciosProducto.precioBase,
          precioMayorista: preciosProducto.precioMayorista,
          precioOferta: preciosProducto.precioOferta,
          sucursalId: createProductoDto.sucursalId,
          stock: inventarioProducto.stock
        }
      })

      return insertedProductResult
    } catch (error) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar crear el producto'
      )
    }
  }

  private async validateRelacionados(createProductoDto: CreateProductoDto) {
    const results = await db
      .select({
        sucursalId: sucursalesTable.id,
        unidadNombre: unidadesTable.nombre,
        categoriaNombre: categoriasTable.nombre,
        marcaNombre: marcasTable.nombre
      })
      .from(sucursalesTable)
      .leftJoin(unidadesTable, eq(unidadesTable.id, createProductoDto.unidadId))
      .leftJoin(
        categoriasTable,
        eq(categoriasTable.id, createProductoDto.categoriaId)
      )
      .leftJoin(marcasTable, eq(marcasTable.id, createProductoDto.marcaId))
      .where(eq(sucursalesTable.id, createProductoDto.sucursalId))

    if (results.length < 1) {
      throw CustomError.badRequest('La sucursal que intentó asignar no existe')
    }

    const [result] = results

    if (result.unidadNombre === null) {
      throw CustomError.badRequest('La unidad que intentó asignar no existe')
    }

    if (result.categoriaNombre === null) {
      throw CustomError.badRequest('La categoría que intentó asignar no existe')
    }

    if (result.marcaNombre === null) {
      throw CustomError.badRequest('La marca que intentó asignar no existe')
    }

    const productsWithSameSkuNombre = await db
      .select({ sku: productosTable.sku, nombre: productosTable.nombre })
      .from(productosTable)
      .where(
        or(
          ilike(productosTable.sku, createProductoDto.sku),
          ilike(productosTable.nombre, createProductoDto.nombre)
        )
      )

    if (productsWithSameSkuNombre.length > 0) {
      const [producto] = productsWithSameSkuNombre

      if (producto.sku === createProductoDto.sku) {
        throw CustomError.badRequest(
          `Ya existe un producto con ese sku ${createProductoDto.sku}`
        )
      }

      if (producto.nombre === createProductoDto.nombre) {
        throw CustomError.badRequest(
          `Ya existe un producto con ese nombre ${createProductoDto.nombre}`
        )
      }
    }

    return {
      unidadNombre: result.unidadNombre,
      categoriaNombre: result.categoriaNombre,
      marcaNombre: result.marcaNombre
    }
  }

  async execute(createProductoDto: CreateProductoDto) {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionCreateAny]
    )

    if (
      !validPermissions.some(
        (permission) => permission.codigoPermiso === this.permissionCreateAny
      )
    ) {
      throw CustomError.forbidden(
        'No tienes los suficientes permisos para realizar esta acción'
      )
    }

    const relacionados = await this.validateRelacionados(createProductoDto)
    const producto = await this.createProducto(createProductoDto)

    const mappedProducto = ProductoEntityMapper.fromObject({
      ...producto,
      relacionados
    })

    return mappedProducto
  }
}
