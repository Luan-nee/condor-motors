import { orderValues } from '@/consts'
import { parseBoolString } from '@/core/lib/utils'
import { db } from '@/db/connection'
import {
  categoriasTable,
  coloresTable,
  detallesProductoTable,
  marcasTable,
  productosTable
} from '@/db/schema'
import type { QueriesProductoDto } from '@/domain/dtos/entities/productos/queries-producto.dto'
import { and, asc, desc, eq, ilike, or, type SQL } from 'drizzle-orm'

export class GetProductosNombre {
  private readonly selectFields = {
    id: productosTable.id,
    nombre: productosTable.nombre,
    sku: productosTable.sku,
    descripcion: productosTable.descripcion,
    maxDiassinReastecer: productosTable.maxDiasSinReabastecer,
    stockMinimo: productosTable.stockMinimo,
    porcentajeDescuento: productosTable.porcentajeDescuento,
    cantidadMinimaDescuento: productosTable.cantidadMinimaDescuento,
    cantidadGratisDescuento: productosTable.cantidadGratisDescuento,
    pathFoto: productosTable.pathFoto,
    marca: marcasTable.nombre,
    color: coloresTable.nombre,
    categoria: categoriasTable.nombre
  }

  private getFilterCondition(queriesProductoDto: QueriesProductoDto) {
    const { stockBajo } = queriesProductoDto
    const conditions: SQL[] = []
    if (stockBajo !== undefined) {
      const stockBajoBoolean = parseBoolString(stockBajo)

      if (stockBajoBoolean !== undefined) {
        conditions.push(eq(detallesProductoTable.stockBajo, stockBajoBoolean))
      }
    }
    return and(...conditions)
  }

  private readonly validSortBy = {
    fechaCreacion: productosTable.fechaCreacion,
    fechaActualizacion: productosTable.fechaActualizacion,
    nombre: productosTable.nombre
  }

  private isValidSortBy(
    sortBy: string
  ): sortBy is keyof typeof this.validSortBy {
    return Object.keys(this.validSortBy).includes(sortBy)
  }
  private getSortByColumn(sortBy: string) {
    if (
      Object.keys(this.validSortBy).includes(sortBy) &&
      this.isValidSortBy(sortBy)
    ) {
      return this.validSortBy[sortBy]
    }

    return this.validSortBy.fechaCreacion
  }
  private async getProductos(queriesDto: QueriesProductoDto) {
    const sortByColumn = this.getSortByColumn(queriesDto.sort_by)

    const order =
      queriesDto.order === orderValues.asc
        ? asc(sortByColumn)
        : desc(sortByColumn)

    const busquedaCondition =
      queriesDto.search.length > 0
        ? or(
            ilike(productosTable.nombre, `%${queriesDto.search}%`),
            ilike(productosTable.descripcion, `%${queriesDto.search}%`)
          )
        : undefined

    const filterCondition = this.getFilterCondition(queriesDto)

    const whereCondition = and(busquedaCondition, filterCondition)

    const productos = await db
      .select(this.selectFields)
      .from(productosTable)
      .innerJoin(marcasTable, eq(marcasTable.id, productosTable.marcaId))
      .innerJoin(coloresTable, eq(coloresTable.id, productosTable.colorId))
      .innerJoin(
        categoriasTable,
        eq(categoriasTable.id, productosTable.categoriaId)
      )
      .where(whereCondition)
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))

    return productos
  }

  async execute(queriesDto: QueriesProductoDto) {
    const productos = await this.getProductos(queriesDto)
    return productos
  }
}
