import { db } from '@/db/connection'
import { coloresTable, productosTable } from '@/db/schema'
import { asc, count, eq } from 'drizzle-orm'

export class GetColores {
  private readonly SelectFields = {
    id: coloresTable.id,
    nombre: coloresTable.nombre,
    hex: coloresTable.hex,
    totalProductos: count(productosTable.id)
  }

  async execute() {
    const colores = await db
      .select(this.SelectFields)
      .from(coloresTable)
      .leftJoin(productosTable, eq(coloresTable.id, productosTable.colorId))
      .groupBy(coloresTable.id)
      .orderBy(asc(coloresTable.nombre))

    return colores
  }
}
