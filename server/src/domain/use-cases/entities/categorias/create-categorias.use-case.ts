import { CustomError } from '@/core/errors/custom.error'
import { categoriasTable } from '@/db/schema'
import type { CreateCategoriaDto } from '@/domain/dtos/entities/categorias/create-categoria.dto'
import { db } from '@db/connection'
import { ilike } from 'drizzle-orm'

export class CreateCategoria {
  private readonly authPayload: AuthPayload
  constructor(authpayload: AuthPayload) {
    this.authPayload = authpayload
  }

  private async createCategoria(createCategoriaDto: CreateCategoriaDto) {
    const validarNombre = await db
      .select()
      .from(categoriasTable)
      .where(ilike(categoriasTable.nombre, createCategoriaDto.nombre))

    if (validarNombre.length > 0) {
      throw CustomError.badRequest(
        ` El nombre ${createCategoriaDto.nombre} ya esta en uso ${this.authPayload.id} `
      )
    }

    const InsertarCategoria = await db
      .insert(categoriasTable)
      .values({
        nombre: createCategoriaDto.nombre,
        descripcion: createCategoriaDto.descripcion
      })
      .returning()

    if (InsertarCategoria.length <= 0) {
      throw CustomError.internalServer(
        'Ocurrio un error al ingresar la categoria'
      )
    }

    const [categoria] = InsertarCategoria
    return categoria
  }

  async execute(createCategoriaDto: CreateCategoriaDto) {
    const categoria = await this.createCategoria(createCategoriaDto)
    return categoria
  }
}
