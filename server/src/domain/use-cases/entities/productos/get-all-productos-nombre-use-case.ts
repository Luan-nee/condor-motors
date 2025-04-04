import { orderValues } from '@/consts'
import { db } from '@/db/connection'
import { productosTable } from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { asc, desc, ilike, or } from 'drizzle-orm'

export class GetProductosNombre {
  private readonly selectFields = {
    id: productosTable.id,
    nombre: productosTable.nombre,
    descripcion: productosTable.descripcion
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
  private async getProductos(queriesDto: QueriesDto) {
    const sortByColumn = this.getSortByColumn(queriesDto.sort_by)

    const order =
      queriesDto.order === orderValues.asc
        ? asc(sortByColumn)
        : desc(sortByColumn)

    const whereCondition =
      queriesDto.search.length > 0
        ? or(
            ilike(productosTable.nombre, `%${queriesDto.search}%`),
            ilike(productosTable.descripcion, `%${queriesDto.search}%`)
          )
        : undefined

    const productos = await db
      .select(this.selectFields)
      .from(productosTable)
      .where(whereCondition)
      .orderBy(order)

    return productos
  }

  async execute(queriesDto: QueriesDto) {
    const productos = await this.getProductos(queriesDto)
    return productos
  }
}
