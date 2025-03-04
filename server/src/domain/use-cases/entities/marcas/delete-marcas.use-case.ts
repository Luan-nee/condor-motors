import { marcasTable } from '@/db/schema'
import { db } from '@db/connection'
import { eq } from 'drizzle-orm'

interface DeleteMarcasUseCase {
  execute: (id: number) => Promise<any>
}

export class DeleteMarcas implements DeleteMarcasUseCase {
  async execute(id: number): Promise<any> {
    const marca = await db
      .delete(marcasTable)
      .where(eq(marcasTable.id, id))
      .returning()

    return marca[0]
  }
}
