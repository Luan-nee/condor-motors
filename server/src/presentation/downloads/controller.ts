import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { FileQueriesDto } from '@/domain/dtos/downloads/file-queries.dto'
import { FilenameDto } from '@/domain/dtos/query-params/filename.dto'
import { DownloadApkDesktopApp } from '@/domain/use-cases/downloads/download-apk-desktop-app.use-case'
import type { TokenAuthenticator } from '@/types/interfaces'
import type { Request, Response } from 'express'

export class DownloadsController {
  constructor(
    private readonly tokenAuthenticator: TokenAuthenticator,
    private readonly privateStoragePath: string
  ) {}

  apkDesktopApp = (req: Request, res: Response) => {
    const [error, filenameDto] = FilenameDto.create(req.params)
    if (error != null || filenameDto == null) {
      CustomResponse.notFound({ res })
      return
    }

    const [queriesError, fileQueriesDto] = FileQueriesDto.create(req.query)
    if (queriesError != null || fileQueriesDto == null) {
      CustomResponse.notFound({ res })
      return
    }

    const downloadApkDesktopApp = new DownloadApkDesktopApp(
      this.tokenAuthenticator,
      this.privateStoragePath
    )

    downloadApkDesktopApp
      .execute(filenameDto, fileQueriesDto)
      .then((file) => {
        res.download(file.filePath, (error) => {
          // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
          if (error != null) {
            CustomResponse.internalServer({ res, error })
          }
        })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
