import { CustomError } from '@/core/errors/custom.error'
import type { FileQueriesDto } from '@/domain/dtos/downloads/file-queries.dto'
import type { FilenameDto } from '@/domain/dtos/query-params/filename.dto'
import type { TokenAuthenticator } from '@/types/interfaces'
import { stat } from 'node:fs/promises'
import path from 'node:path'

export class DownloadApkDesktopApp {
  constructor(private readonly tokenAuthenticator: TokenAuthenticator) {}

  async execute(filenameDto: FilenameDto, fileQueriesDto: FileQueriesDto) {
    if (
      !this.tokenAuthenticator.validateDownloadToken({
        token: fileQueriesDto.tk,
        payload: filenameDto,
        expiresAt: fileQueriesDto.exp
      })
    ) {
      throw CustomError.unauthorized('El token de descarga ha vencido')
    }

    const basePrivatePath = 'storage/private/'
    const filepath = path.join(
      process.cwd(),
      basePrivatePath,
      filenameDto.filename
    )

    try {
      await stat(filepath)
    } catch {
      throw CustomError.notFound('El archivo no existe')
    }

    return { filepath }
  }
}
