import { getDateTimeString, getOffsetDateTime } from '@/core/lib/utils'
import { db } from '@/db/connection'
import { sucursalesTable, totalesVentaTable, ventasTable } from '@/db/schema'
import { count, eq, gte, sum } from 'drizzle-orm'

export class GetReporteVentas {
  private async getventasReporte() {
    const fechaActual = getOffsetDateTime(new Date(), -5)
    if (fechaActual === undefined) {
      return []
    }
    const fecha = getDateTimeString(fechaActual)
    const hoy = getOffsetDateTime(new Date(fecha.date), 5)
    if (hoy === undefined) {
      return []
    }
    const primerDiaMes = new Date(fechaActual.getDate())
    primerDiaMes.setDate(1)
    const inicioMes = getOffsetDateTime(primerDiaMes, 5)

    if (inicioMes === undefined) {
      return []
    }

    const ultimoDiaMes = new Date(fechaActual.getDate())
    ultimoDiaMes.setMonth(ultimoDiaMes.getMonth() + 1, 0)
    const finMes = getOffsetDateTime(ultimoDiaMes, 5)

    if (finMes === undefined) {
      return []
    }

    const getVentasMes = await db
      .select({ esteMes: count(ventasTable.id) })
      .from(ventasTable)
      .where(gte(ventasTable.fechaCreacion, inicioMes))
    const [esteMes] = getVentasMes
    const whereCondition = undefined
    // queriesDto.startDate instanceof Date && queriesDto.endDate instanceof Date
    //   ? and(
    //       gte(ventasTable.fechaCreacion, new Date(queriesDto.startDate)),
    //       lte(ventasTable.fechaCreacion, new Date(queriesDto.endDate))
    //     )
    //   : queriesDto.startDate instanceof Date
    //     ? gte(ventasTable.fechaCreacion, new Date(queriesDto.startDate))
    //     : undefined

    const dataTotal = await db
      .select({
        hoy: count(),
        esteMes: sum(totalesVentaTable.totalVenta)
      })
      .from(totalesVentaTable)
      .innerJoin(ventasTable, eq(totalesVentaTable.ventaId, ventasTable.id))
      .where(whereCondition)

    const getVentaHoy = await db
      .select({ hoy: count(ventasTable.id) })
      .from(ventasTable)
      .where(gte(ventasTable.fechaCreacion, hoy))

    const sucursales = await db
      .select({
        nombre: sucursalesTable.nombre,
        ventas: count(),
        totalVentas: sum(totalesVentaTable.totalVenta)
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

    const [ventas] = dataTotal
    const [hoyDia] = getVentaHoy

    const totalVentas = {
      ...hoyDia,
      ...esteMes
    }

    return {
      ventas,
      totalVentas,
      sucursales
    }
  }

  async execute() {
    const reporteVentas = await this.getventasReporte()

    return reporteVentas
  }
}
