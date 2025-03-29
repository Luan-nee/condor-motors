import { db } from '@/db/connection'
import { sucursalesTable, totalesVentaTable, ventasTable } from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { and, count, eq, gte, lte, sum } from 'drizzle-orm'

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

    const dataTotal = await db
      .select({
        ventasTotales: count(),
        totalVendido: sum(totalesVentaTable.totalVenta)
      })
      .from(totalesVentaTable)
      .innerJoin(ventasTable, eq(totalesVentaTable.ventaId, ventasTable.id))
      .where(whereCondition)

    const getVentas = await db
      .select({
        nombreSucursal: sucursalesTable.nombre,
        totalVentas: count(),
        sumaVenta: sum(totalesVentaTable.totalVenta)
      })
      .from(ventasTable)
      .innerJoin(
        sucursalesTable,
        eq(sucursalesTable.id, ventasTable.sucursalId)
      )
      .innerJoin(
        totalesVentaTable,
        eq(totalesVentaTable.ventaId, ventasTable.id)
      )
      .where(whereCondition)
      .groupBy(ventasTable.sucursalId, sucursalesTable.nombre)

    const [data] = dataTotal

    return {
      ...data,
      getVentas
    }
  }

  async execute(queriesDto: QueriesDto) {
    const reporteVentas = await this.getventasReporte(queriesDto)

    return reporteVentas
  }
}
