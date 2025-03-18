import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { categoriasTable, empleadosTable } from '@/db/schema'
import type { UpdateCategoriaDto } from '@/domain/dtos/entities/categorias/update-categoria.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { eq, ilike, count } from 'drizzle-orm'

export class UpdateCategoria {
  async execute(
    updateCategoriaDto: UpdateCategoriaDto,
    numericIdDto: NumericIdDto
  ) {
    const categorias = await db
      .select()
      .from(categoriasTable)
      .where(eq(categoriasTable.id, numericIdDto.id))

    if (categorias.length <= 0) {
      throw CustomError.badRequest(
        `No se encontro ninguna categoria con el id '${numericIdDto.id}'`
      )
    }

    if (updateCategoriaDto.nombre !== undefined) {
      const categoriaConNombre = await db
        .select({ count: count() })
        .from(categoriasTable)
        .where(ilike(categoriasTable.nombre, updateCategoriaDto.nombre))

      if (Number(categoriaConNombre[0]) > 0) {
        throw CustomError.badRequest(
          `El nombre '${updateCategoriaDto.nombre}' ya esta en uso`
        )
      }
    }

    const updateCategoria = await db
      .update(categoriasTable)
      .set({
        nombre: updateCategoriaDto.nombre,
        descripcion: updateCategoriaDto.descripcion
      })
      .where(eq(empleadosTable.id, numericIdDto.id))
      .returning()

    if (updateCategoria.length <= 0) {
      throw CustomError.internalServer(
        `Ocurrio un error al momento de actualizar los datos ${numericIdDto.id}`
      )
    }

    const [categoria] = updateCategoria
    return categoria
  }
}
