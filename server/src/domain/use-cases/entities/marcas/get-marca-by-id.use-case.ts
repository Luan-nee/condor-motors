import { marcasTable } from '@/db/schema'
import { db } from '@db/connection'
import { eq } from 'drizzle-orm'

interface GetMarcaByIdUseCase {
  execute: (id: number) => Promise<any>
}

export class GetMarcaById implements GetMarcaByIdUseCase {
  async execute(id: number): Promise<any> {
    const marca = await db
      .select()
      .from(marcasTable)
      .where(eq(marcasTable.id, id))
    
    return marca[0] || null
  }
} 