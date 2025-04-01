import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { GetByIdData } from '@/domain/use-cases/entities/productos/get-bt-id-dates-use-case'
import type { Request, Response } from 'express'

export class ProductosController {
  detalles = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.invalidAccessToken({ res })
    }

    if (req.idProducto === undefined) {
      CustomResponse.badRequest({ res, error: 'Id de producto Invalido' })
      return
    }

    const { idProducto } = req

    const getProdcutoById = new GetByIdData()

    getProdcutoById
      .execute(idProducto)
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
