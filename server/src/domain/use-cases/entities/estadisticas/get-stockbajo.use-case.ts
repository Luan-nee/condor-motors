import { db } from '@/db/connection'
import { detallesProductoTable } from '@/db/schema'
import { count, eq } from 'drizzle-orm'

export class GetStockBajoLiquidacion {
  private async getStockLiquidacionColumn() {
    const getStockBajo = await db
      .select({ stockBajo: count() })
      .from(detallesProductoTable)
      .where(eq(detallesProductoTable.stockBajo, true))

    const getLiquidacion = await db
      .select({ cantidadLiquidacion: count() })
      .from(detallesProductoTable)
      .where(eq(detallesProductoTable.liquidacion, true))

    const [stockBajo] = getStockBajo
    const [liquidacion] = getLiquidacion

    return { ...stockBajo, ...liquidacion }
  }

  async execute() {
    const reporteStockLiquidacion = await this.getStockLiquidacionColumn()
    return reporteStockLiquidacion
  }
}
