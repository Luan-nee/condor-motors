import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { GetColores } from '@/domain/use-cases/entities/colores/get-colores.use.case'
import type { Request, Response } from 'express'

export class ColoresController {
  getAll = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
    }
    const getColores = new GetColores()

    getColores
      .execute()
      .then((color) => {
        CustomResponse.success({ res, data: color })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
