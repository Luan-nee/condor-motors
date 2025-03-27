import { marcasTable, productosTable } from '@/db/schema'
import { db } from '@db/connection'
import { count, eq } from 'drizzle-orm'

interface GetMarcaByIdUseCase {
  execute: (id: number) => Promise<any>
}

export class GetMarcaById implements GetMarcaByIdUseCase {
  private readonly selectFields = {
    id: marcasTable.id,
    nombre: marcasTable.nombre,
    descripcion: marcasTable.descripcion,
    totalProductos: count(productosTable.id)
  }

  async execute(id: number): Promise<any> {
    const marca = await db
      .select(this.selectFields)
      .from(marcasTable)
      .leftJoin(productosTable, eq(marcasTable.id, productosTable.marcaId))
      .where(eq(marcasTable.id, id))
      .groupBy(marcasTable.id)

    return marca.length > 0 ? marca[0] : null
  }
}
