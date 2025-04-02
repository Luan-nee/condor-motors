import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { categoriasTable, productosTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { count, eq } from 'drizzle-orm'

export class DeleteCategoria {
  private async deleteCategoria(numericIdDto: NumericIdDto) {
    const [validarProductos] = await db
      .select({ count: count(productosTable.id) })
      .from(productosTable)
      .where(eq(productosTable.categoriaId, numericIdDto.id))

    if (validarProductos.count > 0) {
      throw CustomError.badRequest(
        `No se pudo eliminar la categoria por que tienen datos relacionados`
      )
    }

    const deleteCat = await db
      .delete(categoriasTable)
      .where(eq(categoriasTable.id, numericIdDto.id))
      .returning({ id: categoriasTable.id })
    if (deleteCat.length <= 0) {
      throw CustomError.badRequest(
        ` No se pudo eliminar la categoria por problemas internos`
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
