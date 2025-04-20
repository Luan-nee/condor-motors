import { CustomError } from '@/core/errors/custom.error'
import { getDateTimeString, getOffsetDateTime } from '@/core/lib/utils'
import { db } from '@/db/connection'
import { sucursalesTable, totalesVentaTable, ventasTable } from '@/db/schema'
import { count, eq, gte, isNull, or, sql } from 'drizzle-orm'

export class GetReporteVentas {
  private async getventasReporte() {
    const currentOffsetDateTime = getOffsetDateTime(new Date(), -5)

    if (currentOffsetDateTime === undefined) {
      throw CustomError.internalServer()
    }

    const dateTime = getDateTimeString(currentOffsetDateTime)
    const today = getOffsetDateTime(new Date(dateTime.date), 5)

    if (today === undefined) {
      throw CustomError.internalServer()
    }

    const firstDayThisMonth = new Date(today)
    firstDayThisMonth.setDate(1)

    const [salesToday] = await db
      .select({
        count: count(ventasTable.id),
        total: sql<string>`coalesce(sum(${totalesVentaTable.totalVenta}), 0)`
      })
      .from(ventasTable)
      .innerJoin(
        totalesVentaTable,
        eq(ventasTable.id, totalesVentaTable.ventaId)
      )
      .where(gte(ventasTable.fechaCreacion, today))

    const [salesThisMonth] = await db
      .select({
        count: count(ventasTable.id),
        total: sql<string>`coalesce(sum(${totalesVentaTable.totalVenta}), 0)`
      })
      .from(ventasTable)
      .innerJoin(
        totalesVentaTable,
        eq(ventasTable.id, totalesVentaTable.ventaId)
      )
      .where(gte(ventasTable.fechaCreacion, firstDayThisMonth))

    const sucursales = await db
      .select({
        id: sucursalesTable.id,
        nombre: sucursalesTable.nombre,
        ventas: count(ventasTable.id),
        totalVentas: sql<string>`coalesce(sum(${totalesVentaTable.totalVenta}), 0)`
      })
      .from(sucursalesTable)
      .leftJoin(ventasTable, eq(sucursalesTable.id, ventasTable.sucursalId))
      .leftJoin(
        totalesVentaTable,
        eq(ventasTable.id, totalesVentaTable.ventaId)
      )
      .where(
        or(
          isNull(ventasTable.id),
          gte(ventasTable.fechaCreacion, firstDayThisMonth)
        )
      )
      .groupBy(sucursalesTable.id)

    return {
      ventas: {
        hoy: salesToday.count,
        esteMes: salesThisMonth.count
      },
      totalVentas: {
        hoy: salesToday.total,
        esteMes: salesThisMonth.total
      },
      sucursales
    }
  }

  async execute() {
    const reporteVentas = await this.getventasReporte()

    return reporteVentas
  }
}
