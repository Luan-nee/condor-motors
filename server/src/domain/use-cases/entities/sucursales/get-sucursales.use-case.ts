import { orderValues } from '@/consts'
import { db } from '@/db/connection'
import { sucursalesTable } from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { QueriesMapper } from '@/domain/mappers/queries.mapper'
import { SucursalEntityMapper } from '@/domain/mappers/sucursal-entity.mapper'
import { asc, desc, ilike, or } from 'drizzle-orm'

export class GetSucursales {
  // eslint-disable-next-line @typescript-eslint/class-methods-use-this
  private getSortByColumn(sortBy: string) {
    if (sortBy === sucursalesTable.nombre.name) return sucursalesTable.nombre
    if (sortBy === sucursalesTable.direccion.name) {
      return sucursalesTable.direccion
    }
    if (sortBy === sucursalesTable.sucursalCentral.name) {
      return sucursalesTable.sucursalCentral
    }

    return sucursalesTable.fechaCreacion
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
    const mappedQueries = QueriesMapper.QueriesFromObject(
      queriesDto,
      [
        sucursalesTable.nombre.name,
        sucursalesTable.direccion.name,
        sucursalesTable.sucursalCentral.name
      ],
      sucursalesTable.fechaCreacion.name
    )

    const sucursales = await this.getSucursales(mappedQueries)

    return sucursales.map((sucursal) =>
      SucursalEntityMapper.sucursalEntityFromObject(sucursal)
    )
  }
}
