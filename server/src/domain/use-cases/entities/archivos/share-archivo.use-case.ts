import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { archivosAppTable } from '@/db/schema'
import type { ShareArchivoDto } from '@/domain/dtos/entities/archivos/share-archivo.dto'
import type { TokenAuthenticator } from '@/types/interfaces'
import { like } from 'drizzle-orm'
import { stat } from 'node:fs/promises'
import path from 'node:path'

export class ShareArchivo {
  constructor(
    private readonly tokenAuthenticator: TokenAuthenticator,
    private readonly privateStoragePath: string
  ) {}

  private async shareFile(shareArchivoDto: ShareArchivoDto) {
    const files = await db
      .select({ id: archivosAppTable.id, filename: archivosAppTable.filename })
      .from(archivosAppTable)
      .where(like(archivosAppTable.filename, shareArchivoDto.filename))

    if (files.length < 1) {
      throw CustomError.notFound('El archivo no existe')
    }

    const filePath = path.join(
      this.privateStoragePath,
      shareArchivoDto.filename
    )

    try {
      await stat(filePath)
    } catch {
      throw CustomError.notFound('El archivo no existe')
    }

    const { token, expiresAt } = this.tokenAuthenticator.generateDownloadToken({
      payload: { filename: shareArchivoDto.filename },
      durationMs: shareArchivoDto.duration
    })

    return {
      token,
      expiresAt,
      filename: shareArchivoDto.filename
    }
  }

  async execute(shareArchivoDto: ShareArchivoDto) {
    return await this.shareFile(shareArchivoDto)
  }
}
