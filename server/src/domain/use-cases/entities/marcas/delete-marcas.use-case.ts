import { CustomError } from '@/core/errors/custom.error'
import { marcasTable, productosTable } from '@/db/schema'
import { db } from '@db/connection'
import { count, eq } from 'drizzle-orm'

interface DeleteMarcasUseCase {
  execute: (id: number) => Promise<any>
}

export class DeleteMarcas implements DeleteMarcasUseCase {
  async execute(id: number): Promise<any> {
    const [productosRelacionados] = await db
      .select({ count: count(productosTable.id) })
      .from(productosTable)
      .where(eq(productosTable.marcaId, id))

    if (productosRelacionados.count > 0) {
      // return []
      throw CustomError.badRequest(
        `No se puede eliminar la marca por que tienen datos relacionados `
      )
    }

    const marca = await db
      .delete(marcasTable)
      .where(eq(marcasTable.id, id))
      .returning()

    return marca[0]
  }
}
