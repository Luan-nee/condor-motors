import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { categoriasTable } from '@/db/schema'
import type { UpdateCategoriaDto } from '@/domain/dtos/entities/categorias/update-categoria.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { count, eq, ilike } from 'drizzle-orm'

export class UpdateCategoria {
  private readonly authPayload: AuthPayload
  private readonly permisionAny = permissionCodes.categorias.createAny

  constructor(authpayload: AuthPayload) {
    this.authPayload = authpayload
  }
  private async validatePermissions() {
    const validaPermisos = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permisionAny]
    )
    const hasPermissionAny = validaPermisos.some(
      (permiso) => permiso.codigoPermiso === this.permisionAny
    )
    if (!hasPermissionAny) {
      throw CustomError.forbidden()
    }
  }
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
    await this.validatePermissions()

    const updateCategoria = await db
      .update(categoriasTable)
      .set({
        nombre: updateCategoriaDto.nombre,
        descripcion: updateCategoriaDto.descripcion
      })
      .where(eq(categoriasTable.id, numericIdDto.id))
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
