import { permissionCodes } from '@/consts'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { archivosAppTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { eq } from 'drizzle-orm'
import { stat, unlink } from 'node:fs/promises'

export class DeleteArchivo {
  private readonly permissionAny = permissionCodes.archivos.deleteAny

  constructor(
    // private readonly authPayload: AuthPayload,
    private readonly permissionsList: Permission[]
  ) {}

  private async deleteArchivo(numericIdDto: NumericIdDto) {
    const files = await db
      .select({ id: archivosAppTable.id, filename: archivosAppTable.filename })
      .from(archivosAppTable)
      .where(eq(archivosAppTable.id, numericIdDto.id))

    if (files.length < 1) {
      throw CustomError.badRequest(
        'El archivo no se pudo eliminar (no encontrado)'
      )
    }

    const [fileToDelete] = files

    const path = `storage/private/${fileToDelete.filename}`

    let fileExists = true

    try {
      await stat(path)
    } catch {
      fileExists = false
    }

    if (fileExists) {
      await unlink(`storage/private/${fileToDelete.filename}`)
        .then()
        .catch(() => {
          throw CustomError.internalServer(
            `File not found: ${JSON.stringify(fileToDelete)}`
          )
        })
    }

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

    await this.deleteArchivo(numericIdDto)
  }
}
