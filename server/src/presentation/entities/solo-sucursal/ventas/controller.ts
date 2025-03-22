import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateVentaDto } from '@/domain/dtos/entities/ventas/create-venta.dto'
import { CreateVenta } from '@/domain/use-cases/entities/ventas/create-venta.use-case'
import type { Request, Response } from 'express'

export class VentasController {
  constructor(private readonly tokenFacturacion?: string) {}

  create = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    if (req.sucursalId === undefined) {
      CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
      return
    }

    const [error, createVentaDto] = CreateVentaDto.validate(req.body)
    if (error !== undefined || createVentaDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload, sucursalId } = req

    const createVenta = new CreateVenta(authPayload, this.tokenFacturacion)

    createVenta
      .execute(createVentaDto, sucursalId)
      .then((venta) => {
        CustomResponse.success({ res, data: venta })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  getById = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    if (req.sucursalId === undefined) {
      CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
      return
    }

    CustomResponse.notImplemented({ res })
  }

  getAll = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    if (req.sucursalId === undefined) {
      CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
      return
    }

    CustomResponse.notImplemented({ res })
  }

  update = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    if (req.sucursalId === undefined) {
      CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
      return
    }

    CustomResponse.notImplemented({ res })
  }
}
