import { CustomResponse } from '@/core/responses/custom.response'
import { paramsProductosIdValidator } from '@/domain/validators/query-params/query-params.validator'
import type { NextFunction, Request, Response } from 'express'

export class ProductosMiddleware {
  static readonly soloProductos = (
    req: Request,
    res: Response,
    next: NextFunction
  ) => {
    const result = paramsProductosIdValidator(req.params)

    if (!result.success) {
      CustomResponse.notFound({ res })
      return
    }

    const {
      data: { idProducto }
    } = result

    req.idProducto = idProducto

    next()
  }
}
