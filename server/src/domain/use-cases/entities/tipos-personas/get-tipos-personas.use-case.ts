import { db } from '@/db/connection'
import { tiposPersonasTable } from '@/db/schema'
import { asc } from 'drizzle-orm'

export class GetTiposPersonas {
  private readonly selectFields = {
    id: tiposPersonasTable.id,
    nombre: tiposPersonasTable.nombre,
    codigo: tiposPersonasTable.codigo
  }

  async execute() {
    const tiposPersonas = await db
      .select(this.selectFields)
      .from(tiposPersonasTable)
      .orderBy(asc(tiposPersonasTable.nombre))

    return tiposPersonas
  }
}
