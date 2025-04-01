import { fileTypeValues } from '@/consts'
import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateArchivoDto } from '@/domain/dtos/entities/archivos/create-archivo.dto'
import { CreateArchivo } from '@/domain/use-cases/entities/archivos/create-archivo.use-case'
import type { Request, Response } from 'express'

export class ArchivosController {
  uploadApk = (req: Request, res: Response) => {
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

    if (createArchivoDto.tipo !== fileTypeValues.apk) {
      CustomResponse.badRequest({
        res,
        error: 'El tipo de archivo solo puede ser `apk`'
      })
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

  uploadDesktopApp = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    CustomResponse.notImplemented({ res })
  }

  getAll = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    CustomResponse.notImplemented({ res })
  }

  delete = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    CustomResponse.notImplemented({ res })
  }
}
