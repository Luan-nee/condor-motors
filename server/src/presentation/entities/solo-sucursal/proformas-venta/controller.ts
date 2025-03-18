import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateProformaVentaDto } from '@/domain/dtos/entities/proformas-venta/create-proforma-venta.dto'
import { CreateProformaVenta } from '@/domain/use-cases/entities/proformas-venta/create-proforma-venta.use-case'
import type { Request, Response } from 'express'

export class ProformasVentaController {
  create = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    if (req.sucursalId === undefined) {
      CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
      return
    }

    const [error, createProformaVentaDto] = CreateProformaVentaDto.validate(
      req.body
    )
    if (error !== undefined || createProformaVentaDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload, sucursalId } = req

    const createProformaVenta = new CreateProformaVenta(authPayload)

    createProformaVenta
      .execute(createProformaVentaDto, sucursalId)
      .then((proformaVenta) => {
        CustomResponse.success({ res, data: proformaVenta })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
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

  delete = (req: Request, res: Response) => {
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
