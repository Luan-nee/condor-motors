import { permissionCodes } from '@/consts'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { archivosAppTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { eq } from 'drizzle-orm'
import { stat, unlink } from 'node:fs'

export class DeleteArchivo {
  private readonly permissionAny = permissionCodes.archivos.deleteAny

  constructor(
    // private readonly authPayload: AuthPayload,
    private readonly permissionsList: Permission[]
  ) {}

  private readonly errorNotFound = CustomError.badRequest(
    'El archivo no se pudo eliminar (no encontrado)'
  )

  private async deleteArchivo(numericIdDto: NumericIdDto) {
    const files = await db
      .select({ filename: archivosAppTable.filename })
      .from(archivosAppTable)
      .where(eq(archivosAppTable.id, numericIdDto.id))

    if (files.length < 1) {
      throw this.errorNotFound
    }

    const [fileToDelete] = files

    const path = `storage/private/${fileToDelete.filename}`

    stat(path, (err) => {
      if (err != null) {
        throw this.errorNotFound
      }

      unlink(path, (err) => {
        if (err != null) {
          throw CustomError.internalServer()
        }
      })
    })

    const [file] = await db
      .delete(archivosAppTable)
      .where(eq(archivosAppTable.id, numericIdDto.id))
      .returning({ id: archivosAppTable.id })

    return file
  }

  private validatePermissions() {
    if (
      !this.permissionsList.some((p) => p.codigoPermiso === this.permissionAny)
    ) {
      throw CustomError.forbidden()
    }
  }

  async execute(numericIdDto: NumericIdDto) {
    this.validatePermissions()

    return await this.deleteArchivo(numericIdDto)
  }
}
