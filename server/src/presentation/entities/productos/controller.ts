import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateProductoDto } from '@/domain/dtos/entities/productos/create-producto.dto'
import { CreateProducto } from '@/domain/use-cases/entities/productos/create-producto.use-case'
import type { Request, Response } from 'express'

export class ProductosController {
  create = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res, error: 'Invalid access token' })
      return
    }

    const [error, createProductoDto] = CreateProductoDto.create(req.body)
    if (error !== undefined || createProductoDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload } = req

    const createProducto = new CreateProducto(authPayload)

    createProducto
      .execute(createProductoDto)
      .then((producto) => {
        CustomResponse.success({ res, data: producto })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
