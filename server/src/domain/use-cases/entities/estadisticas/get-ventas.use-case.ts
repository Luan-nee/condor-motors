import { getDateTimeString, getOffsetDateTime } from '@/core/lib/utils'
import { db } from '@/db/connection'
import { sucursalesTable, totalesVentaTable, ventasTable } from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { and, count, eq, gte, lte, sum } from 'drizzle-orm'

export class GetReporteVentas {
  private async getventasReporte(queriesDto: QueriesDto) {
    const fechaActual = getOffsetDateTime(new Date(), -5)
    if (fechaActual === undefined) {
      return []
    }
    const fecha = getDateTimeString(fechaActual)
    const hoy = getOffsetDateTime(new Date(fecha.date), 5)
    if (hoy === undefined) {
      return []
    }
    const valoresPrueba = {
      startDate: fecha,
      hoy
    }

    const whereCondition =
      queriesDto.startDate instanceof Date && queriesDto.endDate instanceof Date
        ? and(
            gte(ventasTable.fechaCreacion, new Date(queriesDto.startDate)),
            lte(ventasTable.fechaCreacion, new Date(queriesDto.endDate))
          )
        : queriesDto.startDate instanceof Date
          ? gte(ventasTable.fechaCreacion, new Date(queriesDto.startDate))
          : undefined

    const dataTotal = await db
      .select({
        ventasTotales: count(),
        totalVendido: sum(totalesVentaTable.totalVenta)
      })
      .from(totalesVentaTable)
      .innerJoin(ventasTable, eq(totalesVentaTable.ventaId, ventasTable.id))
      .where(whereCondition)

    const getVentaHoy = await db
      .select({ ventaDelDia: count(ventasTable.id) })
      .from(ventasTable)
      .where(gte(ventasTable.fechaCreacion, hoy))

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
      getVentaHoy,
      getVentas,
      valoresPrueba
    }
  }

  async execute(queriesDto: QueriesDto) {
    const reporteVentas = await this.getventasReporte(queriesDto)

    return reporteVentas
  }
}
