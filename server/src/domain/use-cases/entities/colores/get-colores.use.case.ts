import { db } from '@/db/connection'
import { coloresTable } from '@/db/schema'
import { asc } from 'drizzle-orm'

export class GetColores {
  private readonly SelectFields = {
    id: coloresTable.id,
    nombre: coloresTable.nombre,
    hex: coloresTable.hex
  }

  async execute() {
    const colores = await db
      .select(this.SelectFields)
      .from(coloresTable)
      .orderBy(asc(coloresTable.nombre))
    return colores
  }
}
