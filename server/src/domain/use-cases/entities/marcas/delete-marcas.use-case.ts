import { CustomError } from '@/core/errors/custom.error'
import { marcasTable, productosTable } from '@/db/schema'
import { db } from '@db/connection'
import { count, eq } from 'drizzle-orm'

interface DeleteMarcasUseCase {
  execute: (id: number) => Promise<any>
}

export class DeleteMarcas implements DeleteMarcasUseCase {
  async execute(id: number): Promise<any> {
    const [productosMismaMarca] = await db
      .select({ count: count(productosTable.id) })
      .from(productosTable)
      .where(eq(productosTable.marcaId, id))

    if (productosMismaMarca.count > 0) {
      throw CustomError.badRequest(
        `No se puede eliminar la categoria porque existen (${productosMismaMarca.count}) productos asociados a esta`
      )
    }

    const marca = await db
      .delete(marcasTable)
      .where(eq(marcasTable.id, id))
      .returning()

    if (marca.length < 1) {
      throw CustomError.badRequest(
        `No se pudo eliminar esta marca (No se encontró)`
      )
    }

    return marca[0]
  }
}
