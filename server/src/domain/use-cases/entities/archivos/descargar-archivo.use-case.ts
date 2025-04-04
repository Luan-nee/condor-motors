import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { archivosAppTable } from '@/db/schema'
import type { FilenameDto } from '@/domain/dtos/query-params/filename.dto'
import { like } from 'drizzle-orm'
import { stat } from 'node:fs/promises'

export class DescargarArchivo {
  async execute(filenameDto: FilenameDto) {
    const files = await db
      .select({ id: archivosAppTable.id, filename: archivosAppTable.filename })
      .from(archivosAppTable)
      .where(like(archivosAppTable.filename, filenameDto.filename))

    if (files.length < 1) {
      throw CustomError.notFound('El archivo no existe')
    }

    const [file] = files

    const path = `storage/private/${file.filename}`

    try {
      await stat(path)
    } catch {
      throw CustomError.notFound('El archivo no existe')
    }

    return {
      ...file,
      path
    }
  }
}
