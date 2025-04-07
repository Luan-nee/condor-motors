import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { archivosAppTable } from '@/db/schema'
import type { FilenameDto } from '@/domain/dtos/query-params/filename.dto'
import { like } from 'drizzle-orm'
import { stat } from 'node:fs/promises'
import path from 'node:path'

export class DescargarArchivo {
  constructor(private readonly privateStoragePath: string) {}

  async execute(filenameDto: FilenameDto) {
    const files = await db
      .select({ id: archivosAppTable.id, filename: archivosAppTable.filename })
      .from(archivosAppTable)
      .where(like(archivosAppTable.filename, filenameDto.filename))

    if (files.length < 1) {
      throw CustomError.notFound('El archivo no existe')
    }

    const [file] = files

    const filePath = path.join(this.privateStoragePath, file.filename)

    try {
      await stat(filePath)
    } catch {
      throw CustomError.notFound('El archivo no existe')
    }

    return {
      ...file,
      path: filePath
    }
  }
}
