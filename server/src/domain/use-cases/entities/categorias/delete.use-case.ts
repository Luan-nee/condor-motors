import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { categoriasTable, productosTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { count, eq } from 'drizzle-orm'

export class DeleteCategoria {
  private async deleteCategoria(numericIdDto: NumericIdDto) {
    const [productosMismaCategoria] = await db
      .select({ count: count(productosTable.id) })
      .from(productosTable)
      .where(eq(productosTable.categoriaId, numericIdDto.id))

    if (productosMismaCategoria.count > 0) {
      throw CustomError.badRequest(
        `No se puede eliminar la categoria porque existen (${productosMismaCategoria.count}) productos asociados a esta`
      )
    }

    const deleteCat = await db
      .delete(categoriasTable)
      .where(eq(categoriasTable.id, numericIdDto.id))
      .returning({ id: categoriasTable.id })
    if (deleteCat.length <= 0) {
      throw CustomError.badRequest(
        'No se pudo eliminar la categoria por problemas internos'
      )
    }
    const [categoria] = deleteCat
    return categoria
  }

  async execute(numericIdDto: NumericIdDto) {
    const categoria = await this.deleteCategoria(numericIdDto)
    return categoria
  }
}
