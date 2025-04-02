import { permissionCodes } from '@/consts'
import { CustomError } from '@/core/errors/custom.error'
import { getFileNameFromPath } from '@/core/lib/utils'
import { db } from '@/db/connection'
import { archivosAppTable } from '@/db/schema'
import type { CreateArchivoDto } from '@/domain/dtos/entities/archivos/create-archivo.dto'
import { eq } from 'drizzle-orm'

interface FileMetadata {
  fieldname: string
  originalname: string
  encoding: string
  mimetype: string
  destination: string
  filename: string
  path: string
  size: number
}

export class CreateArchivo {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.archivos.createAny
  private readonly permissionsList: Permission[]

  constructor(authPayload: AuthPayload, permissionsList: Permission[]) {
    this.authPayload = authPayload
    this.permissionsList = permissionsList
  }

  private async saveFile(
    createArchivoDto: CreateArchivoDto,
    fileMetadata: FileMetadata
  ) {
    const filename = getFileNameFromPath(fileMetadata.path)

    const files = await db
      .select({ filename: archivosAppTable.filename })
      .from(archivosAppTable)
      .where(eq(archivosAppTable.filename, filename))

    if (files.length > 1) {
      throw CustomError.internalServer('Duplicated filenames... how?')
    }

    const now = new Date()

    const [file] = await db
      .insert(archivosAppTable)
      .values({
        nombre: createArchivoDto.nombre,
        filename,
        tipo: createArchivoDto.tipo,
        size: fileMetadata.size.toString(),
        metadata: {
          originalName: fileMetadata.originalname,
          encoding: fileMetadata.encoding,
          mimetype: fileMetadata.mimetype
        },
        visible: createArchivoDto.visible,
        userId: this.authPayload.id,
        fechaCreacion: now,
        fechaActualizacion: now
      })
      .returning()

    return file
  }

  private validatePermissions() {
    if (
      !this.permissionsList.some((p) => p.codigoPermiso === this.permissionAny)
    ) {
      throw CustomError.forbidden()
    }
  }

  async execute(
    createArchivoDto: CreateArchivoDto,
    fileMetadata: FileMetadata
  ) {
    this.validatePermissions()

    return await this.saveFile(createArchivoDto, fileMetadata)
  }
}
