import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { GetByIdData } from '@/domain/use-cases/entities/productos/get-bt-id-dates-use-case'
import type { Request, Response } from 'express'

export class ProductosController {
  detalles = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.invalidAccessToken({ res })
    }

    const [error, numericIdDto] = NumericIdDto.create(req.params)
    if (error != null || numericIdDto == null) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const getProdcutoById = new GetByIdData()

    getProdcutoById
      .execute(numericIdDto.id)
      .then((data) => {
        CustomResponse.success({
          res,
          data
        })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
