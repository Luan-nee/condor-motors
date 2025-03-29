import { db } from '@/db/connection'
import { ventasTable } from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { and, count, gte, lte } from 'drizzle-orm'

export class GetReporteVentas {
  private async getventasReporte(queriesDto: QueriesDto) {
    const fechaActual = new Date()
    fechaActual.setDate(fechaActual.getDate() - 5)

    const whereCondition =
      queriesDto.startDate instanceof Date && queriesDto.endDate instanceof Date
        ? and(
            gte(ventasTable.fechaCreacion, new Date(queriesDto.page)),
            lte(ventasTable.fechaCreacion, new Date(queriesDto.page_size))
          )
        : undefined

    const getVentas = await db
      .select({
        sucursalId: ventasTable.sucursalId,
        totalVentas: count()
      })
      .from(ventasTable)
      .where(whereCondition)
      .groupBy(ventasTable.sucursalId)

    return getVentas
  }

  async execute(queriesDto: QueriesDto) {
    const reporteVentas = await this.getventasReporte(queriesDto)

    return reporteVentas
  }
}
