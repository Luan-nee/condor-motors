import { db } from '@/db/connection'
import { detallesProductoTable, sucursalesTable } from '@/db/schema'
import { count, eq, sql, sum } from 'drizzle-orm'

export class GetStockBajoLiquidacion {
  private async getStockLiquidacionColumn() {
    const sucursales = await db
      .select({
        id: detallesProductoTable.sucursalId,
        nombre: sucursalesTable.nombre,
        stockBajo: sum(
          sql<number>`CASE WHEN ${detallesProductoTable.stockBajo} = true THEN 1 ELSE 0 END`
        ),
        liquidacion: sum(
          sql<number>`CASE WHEN ${detallesProductoTable.liquidacion} = true THEN 1 ELSE 0 END`
        )
      })
      .from(detallesProductoTable)
      .innerJoin(
        sucursalesTable,
        eq(detallesProductoTable.sucursalId, sucursalesTable.id)
      )
      .groupBy(detallesProductoTable.sucursalId, sucursalesTable.nombre)

    const getStockBajo = await db
      .select({ stockBajo: count() })
      .from(detallesProductoTable)
      .where(eq(detallesProductoTable.stockBajo, true))

    const getLiquidacion = await db
      .select({ cantidadLiquidacion: count() })
      .from(detallesProductoTable)
      .where(eq(detallesProductoTable.liquidacion, true))

    const [stockBajo] = getStockBajo
    const [cantidadLiquidacion] = getLiquidacion

    return { ...stockBajo, ...cantidadLiquidacion, sucursales }
  }

  async execute() {
    const reporteStockLiquidacion = await this.getStockLiquidacionColumn()
    return reporteStockLiquidacion
  }
}
