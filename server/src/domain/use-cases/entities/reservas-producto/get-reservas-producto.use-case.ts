import { orderValues } from '@/consts'
import { db } from '@/db/connection'
import {
  clientesTable,
  reservasProductosTable,
  sucursalesTable
} from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { asc, desc, eq, ilike, or, type SQL } from 'drizzle-orm'

export class GetReservasProductos {
  private readonly selectFields = {
    id: reservasProductosTable.id,
    descripcion: reservasProductosTable.descripcion,
    detallesReserva: reservasProductosTable.detallesReserva,
    montoAdelantado: reservasProductosTable.montoAdelantado,
    fechaRecojo: reservasProductosTable.fechaRecojo,
    denominacion: clientesTable.denominacion,
    clienteId: reservasProductosTable.clienteId,
    sucursalId: reservasProductosTable.sucursalId,
    nombre: sucursalesTable.nombre,
    fechaCreacion: reservasProductosTable.fechaCreacion
  }

  private readonly validSortBy = {
    fechaCreacion: reservasProductosTable.fechaCreacion,
    descripcion: reservasProductosTable.descripcion,
    clienteId: reservasProductosTable.clienteId,
    sucursalId: reservasProductosTable.sucursalId
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

  private async getRelatedReservasProductos(
    queriesDto: QueriesDto,
    order: SQL,
    whereCondition: SQL | undefined
  ) {
    return await db
      .select(this.selectFields)
      .from(reservasProductosTable)
      .innerJoin(
        clientesTable,
        eq(clientesTable.id, reservasProductosTable.clienteId)
      )
      .innerJoin(
        sucursalesTable,
        eq(sucursalesTable.id, reservasProductosTable.sucursalId)
      )
      .where(whereCondition)
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))
  }

  private async getReservasProductos(queriesDto: QueriesDto) {
    const sortByColumn = this.getSortByColumn(queriesDto.sort_by)

    const order =
      queriesDto.order === orderValues.asc
        ? asc(sortByColumn)
        : desc(sortByColumn)

    const whereCondition =
      queriesDto.search.length > 0
        ? or(
            ilike(reservasProductosTable.descripcion, `%${queriesDto.search}%`),
            ilike(reservasProductosTable.fechaRecojo, `%${queriesDto.search}%`)
          )
        : undefined

    const reservasP = await this.getRelatedReservasProductos(
      queriesDto,
      order,
      whereCondition
    )

    if (reservasP.length < 1) {
      return []
    }
    return reservasP
  }

  async execute(queriesDto: QueriesDto) {
    const reservasProducto = await this.getReservasProductos(queriesDto)

    return reservasProducto
  }
}
