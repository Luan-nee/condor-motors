import { orderValues } from '@/consts'
import { db } from '@/db/connection'
import { categoriasTable, productosTable } from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { asc, count, desc, eq, ilike, or } from 'drizzle-orm'

export class GetCategorias {
  private readonly selectFields = {
    id: categoriasTable.id,
    nombre: categoriasTable.nombre,
    descripcion: categoriasTable.descripcion,
    totalProductos: count(productosTable.id)
  }

  private readonly validSortBy = {
    nombre: categoriasTable.nombre,
    totalProductos: count(productosTable.id)
  } as const

  private isValidSortBy(
    sortBy: string
  ): sortBy is keyof typeof this.validSortBy {
    return Object.keys(this.validSortBy).includes(sortBy)
  }

  private getSortByColumn(sortBy: string) {
    if (this.isValidSortBy(sortBy)) {
      return this.validSortBy[sortBy]
    }

    return categoriasTable.nombre
  }

  private async getCategorias(queriesDto: QueriesDto) {
    const sortByColumn = this.getSortByColumn(queriesDto.sort_by)

    const order =
      queriesDto.order === orderValues.asc
        ? asc(sortByColumn)
        : desc(sortByColumn)

    const whereCondition =
      queriesDto.search.length > 0
        ? or(ilike(categoriasTable.nombre, `%${queriesDto.search}%`))
        : undefined

    const categorias = await db
      .select(this.selectFields)
      .from(categoriasTable)
      .leftJoin(
        productosTable,
        eq(categoriasTable.id, productosTable.categoriaId)
      )
      .where(whereCondition)
      .groupBy(categoriasTable.id)
      .orderBy(order)

    return categorias
  }

  private getMetadata() {
    return {
      sortByOptions: Object.keys(this.validSortBy)
    }
  }

  async execute(queriesDto: QueriesDto) {
    const categorias = await this.getCategorias(queriesDto)

    const metadata = this.getMetadata()

    return {
      results: categorias,
      metadata
    }
  }
}
