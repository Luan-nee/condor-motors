import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateArchivoDto } from '@/domain/dtos/entities/archivos/create-archivo.dto'
import { ShareArchivoDto } from '@/domain/dtos/entities/archivos/share-archivo.dto'
import { FilenameDto } from '@/domain/dtos/query-params/filename.dto'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { CreateArchivo } from '@/domain/use-cases/entities/archivos/create-archivo.use-case'
import { DeleteArchivo } from '@/domain/use-cases/entities/archivos/delete-archivo.use-case'
import { DescargarArchivo } from '@/domain/use-cases/entities/archivos/descargar-archivo.use-case'
import { GetArchivos } from '@/domain/use-cases/entities/archivos/get-archivos.use-case'
import { ShareArchivo } from '@/domain/use-cases/entities/archivos/share-archivo.use-case'
import type { TokenAuthenticator } from '@/types/interfaces'
import type { Request, Response } from 'express'
import path from 'node:path'

export class ArchivosController {
  constructor(private readonly tokenAuthenticator: TokenAuthenticator) {}

  uploadFile = (req: Request, res: Response) => {
    if (req.authPayload == null || req.permissions == null) {
      CustomResponse.unauthorized({ res })
      return
    }

    if (req.file == null) {
      CustomResponse.badRequest({
        res,
        error: 'El archivo de la aplicación es requerido'
      })
      return
    }

    const [error, createArchivoDto] = CreateArchivoDto.validate(req.body)
    if (error != null || createArchivoDto == null) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload, permissions, file } = req

    const createArchivo = new CreateArchivo(authPayload, permissions)

    createArchivo
      .execute(createArchivoDto, file)
      .then((file) => {
        CustomResponse.success({ res, data: file })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  getAll = (req: Request, res: Response) => {
    if (req.authPayload == null || req.permissions == null) {
      CustomResponse.unauthorized({ res })
      return
    }

    const { permissions } = req

    const getArchivos = new GetArchivos(permissions)

    getArchivos
      .execute()
      .then((files) => {
        CustomResponse.success({ res, data: files })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  download = (req: Request, res: Response) => {
    if (req.authPayload == null) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [error, filenameDto] = FilenameDto.create(req.params)
    if (error != null || filenameDto == null) {
      CustomResponse.notFound({ res })
      return
    }

    const descargarArchivo = new DescargarArchivo()

    descargarArchivo
      .execute(filenameDto)
      .then((file) => {
        const filePath = path.join(process.cwd(), file.path)
        res.download(filePath, (error) => {
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

  share = (req: Request, res: Response) => {
    if (req.authPayload == null) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [error, shareArchivoDto] = ShareArchivoDto.create(req.body)
    if (error != null || shareArchivoDto == null) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const shareArchivo = new ShareArchivo(this.tokenAuthenticator)

    shareArchivo
      .execute(shareArchivoDto)
      .then((sharedFile) => {
        CustomResponse.success({ res, data: sharedFile })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  delete = (req: Request, res: Response) => {
    if (req.authPayload == null || req.permissions == null) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [error, numericIdDto] = NumericIdDto.create(req.params)
    if (error != null || numericIdDto == null) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { permissions } = req

    const deleteArchivo = new DeleteArchivo(permissions)

    deleteArchivo
      .execute(numericIdDto)
      .then((file) => {
        CustomResponse.success({ res, data: file })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
