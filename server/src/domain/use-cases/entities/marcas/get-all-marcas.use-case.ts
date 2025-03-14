import { marcasTable } from '@/db/schema'
import { db } from '@db/connection'
import { sql } from 'drizzle-orm'

interface GetAllMarcasUseCase {
  execute: (page?: number, pageSize?: number) => Promise<any>
}

export class GetAllMarcas implements GetAllMarcasUseCase {
  async execute(page = 1, pageSize = 10): Promise<any> {
    const offset = (page - 1) * pageSize
    
    const [marcas, totalResult] = await Promise.all([
      db.select().from(marcasTable).limit(pageSize).offset(offset),
      db.select({ count: sql`count(*)` }).from(marcasTable)
    ])
    
    const total = Number(totalResult[0].count)
    
    return {
      data: marcas,
      pagination: {
        page,
        pageSize,
        total,
        totalPages: Math.ceil(total / pageSize)
      }
    }
  }
} 