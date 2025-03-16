import { orderValues } from '@/consts'
import { db } from '@/db/connection'
import { categoriasTable } from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { asc, desc, ilike, or } from 'drizzle-orm'

export class GetCategorias {
  private readonly selectFields = {
    id: categoriasTable.id,
    nombre: categoriasTable.nombre,
    descripcion: categoriasTable.descripcion
  }

  private readonly validSortBy = {
    nombre: categoriasTable.nombre,
    id: categoriasTable.id
  } as const

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

    return this.validSortBy.id
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
      .where(whereCondition)
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))

    return categorias
  }

  async execute(queriesDto: QueriesDto) {
    const categorias = await this.getCategorias(queriesDto)
    return categorias
  }
}
