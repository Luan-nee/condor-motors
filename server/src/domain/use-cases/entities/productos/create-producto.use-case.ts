import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  categoriasTable,
  marcasTable,
  productosTable,
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
          `Ya existe un producto con ese sku ${createProductoDto.nombre}`
        )
      }

      if (producto.nombre === createProductoDto.nombre) {
        throw CustomError.badRequest(
          `Ya existe un producto con ese nombre ${createProductoDto.nombre}`
        )
      }
    }

    const unidades = await db
      .select({
        nombre: unidadesTable.nombre
      })
      .from(unidadesTable)
      .where(eq(unidadesTable.id, createProductoDto.unidadId))

    if (unidades.length < 1) {
      throw CustomError.badRequest('La unidad que intentó asignar no existe')
    }

    const categorias = await db
      .select({
        nombre: categoriasTable.nombre
      })
      .from(categoriasTable)
      .where(eq(categoriasTable.id, createProductoDto.categoriaId))

    if (categorias.length < 1) {
      throw CustomError.badRequest('La categoría que intentó asignar no existe')
    }

    const marcas = await db
      .select({
        nombre: marcasTable.nombre
      })
      .from(marcasTable)
      .where(eq(marcasTable.id, createProductoDto.marcaId))

    if (marcas.length < 1) {
      throw CustomError.badRequest('La marca que intentó asignar no existe')
    }

    const insertedProductResult = await db
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

    if (insertedProductResult.length < 1) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar crear el producto'
      )
    }

    const [selectedUnidad] = unidades
    const [selectedCategoria] = categorias
    const [selectedMarca] = marcas

    const [producto] = insertedProductResult

    return {
      ...producto,
      relacionados: {
        unidadNombre: selectedUnidad.nombre,
        categoriaNombre: selectedCategoria.nombre,
        marcaNombre: selectedMarca.nombre
      }
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

    const producto = await this.createProducto(createProductoDto)

    const mappedProducto = ProductoEntityMapper.fromObject(producto)

    return mappedProducto
  }
}
