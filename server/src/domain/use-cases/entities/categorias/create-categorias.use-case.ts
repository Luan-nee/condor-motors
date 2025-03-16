import { CustomError } from '@/core/errors/custom.error'
import { categoriasTable } from '@/db/schema'
import type { CreateCategoriaDto } from '@/domain/dtos/entities/categorias/create-categoria.dto'
import { db } from '@db/connection'
import { ilike } from 'drizzle-orm'
import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'

export class CreateCategoria {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.categorias.createAny

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async createCategoria(createCategoriaDto: CreateCategoriaDto) {
    const categoriasWithSameName = await db
      .select({ id: categoriasTable.id })
      .from(categoriasTable)
      .where(ilike(categoriasTable.nombre, createCategoriaDto.nombre))

    if (categoriasWithSameName.length > 0) {
      throw CustomError.badRequest(
        `Ya existe una categoría con el nombre ${createCategoriaDto.nombre}`
      )
    }

    const insertedResult = await db
      .insert(categoriasTable)
      .values({
        nombre: createCategoriaDto.nombre,
        descripcion: createCategoriaDto.descripcion
      })
      .returning({ id: categoriasTable.id })

    if (insertedResult.length <= 0) {
      throw CustomError.internalServer(
        'Ha ocurrido un erro al intentar crear la categoría'
      )
    }

    const [categoria] = insertedResult

    return categoria
  }

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny]
    )

    const hasPermissionAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionAny
    )

    if (!hasPermissionAny) {
      throw CustomError.forbidden()
    }
  }

  async execute(createCategoriaDto: CreateCategoriaDto) {
    await this.validatePermissions()

    const categoria = await this.createCategoria(createCategoriaDto)
    return categoria
  }
}
