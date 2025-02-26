import { orderValues } from '@/consts'
import { db } from '@/db/connection'
import { sucursalesTable } from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { SucursalEntityMapper } from '@/domain/mappers/sucursal-entity.mapper'
import { asc, desc, ilike, or } from 'drizzle-orm'

export class GetSucursales {
  private readonly validSortBy = {
    fechaCreacion: sucursalesTable.fechaCreacion,
    nombre: sucursalesTable.nombre,
    direccion: sucursalesTable.direccion,
    sucursalCentral: sucursalesTable.sucursalCentral
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

    return this.validSortBy.fechaCreacion
  }

  async getSucursales(queriesDto: QueriesDto) {
    const sortByColumn = this.getSortByColumn(queriesDto.sort_by)

    const order =
      queriesDto.order === orderValues.asc
        ? asc(sortByColumn)
        : desc(sortByColumn)

    const whereCondition =
      queriesDto.search.length > 0
        ? or(
            ilike(sucursalesTable.nombre, `%${queriesDto.search}%`),
            ilike(sucursalesTable.direccion, `%${queriesDto.search}%`)
          )
        : undefined

    const sucursales = await db
      .select()
      .from(sucursalesTable)
      .where(whereCondition)
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))

    if (sucursales.length <= 0) {
      return []
    }

    return sucursales
  }

  async execute(queriesDto: QueriesDto) {
    const sucursales = await this.getSucursales(queriesDto)

    return sucursales.map((sucursal) =>
      SucursalEntityMapper.sucursalEntityFromObject(sucursal)
    )
  }
}
