import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { GetTiposPersonas } from '@/domain/use-cases/entities/tipos-personas/get-tipos-personas.use-case'
import type { Request, Response } from 'express'

export class TiposPersonasController {
  getAll = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const getTiposPersonas = new GetTiposPersonas()

    getTiposPersonas
      .execute()
      .then((tiposPersonas) => {
        CustomResponse.success({ res, data: tiposPersonas })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
