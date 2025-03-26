import { CustomResponse } from '@/core/responses/custom.response'
import type { Request, Response } from 'express'

export class TransferenciasInventarioController {
  create = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
    }
  }
}
