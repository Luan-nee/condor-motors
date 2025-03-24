import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateReservasProductoDto } from '@/domain/dtos/entities/reservas-producto/create-reservasProducto.dto'
import { CreateReservasProducto } from '@/domain/use-cases/entities/ReservasProducto/create-reservasProducto.use-case'
import type { Request, Response } from 'express'

export class ReservasProductosController {
  create = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [error, createReservasProductoDto] = CreateReservasProductoDto.create(
      req.body
    )

    if (error !== undefined || createReservasProductoDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }
    const createReservasProducto = new CreateReservasProducto()

    createReservasProducto
      .execute(createReservasProductoDto)
      .then((reserva) => {
        CustomResponse.success({ res, data: reserva })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
