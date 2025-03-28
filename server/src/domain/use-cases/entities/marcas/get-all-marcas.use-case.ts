import { marcasTable, productosTable } from '@/db/schema'
import { db } from '@db/connection'
import { count, eq, sql } from 'drizzle-orm'

interface GetAllMarcasUseCase {
  execute: (page?: number, pageSize?: number) => Promise<any>
}

export class GetAllMarcas implements GetAllMarcasUseCase {
  private readonly selectFields = {
    id: marcasTable.id,
    nombre: marcasTable.nombre,
    descripcion: marcasTable.descripcion,
    totalProductos: count(productosTable.id)
  }

  async execute(page = 1, pageSize = 10): Promise<any> {
    const [marcas, totalResult] = await Promise.all([
      db
        .select(this.selectFields)
        .from(marcasTable)
        .leftJoin(productosTable, eq(marcasTable.id, productosTable.marcaId))
        .groupBy(marcasTable.id),
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
