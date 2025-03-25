import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateVentaDto } from '@/domain/dtos/entities/ventas/create-venta.dto'
import { DeclareVentaDto } from '@/domain/dtos/entities/ventas/declare-venta.dto'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { CreateVenta } from '@/domain/use-cases/entities/ventas/create-venta.use-case'
import { DeclareVenta } from '@/domain/use-cases/entities/ventas/declare-venta.use-case'
import { GetVentaById } from '@/domain/use-cases/entities/ventas/get-venta-by-id.use-case'
import type { BillingService } from '@/types/interfaces'
import type { Request, Response } from 'express'

export class VentasController {
  constructor(private readonly billingService: BillingService) {}

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

    const createVenta = new CreateVenta(authPayload)

    createVenta
      .execute(createVentaDto, sucursalId)
      .then((venta) => {
        CustomResponse.success({ res, data: venta })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  declarar = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    if (req.sucursalId === undefined) {
      CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
      return
    }

    const [paramErrors, numericIdDto] = NumericIdDto.create(req.params)
    if (paramErrors !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: paramErrors })
      return
    }

    const [error, declareVentaDto] = DeclareVentaDto.validate(req.body)
    if (error !== undefined || declareVentaDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload, sucursalId } = req

    const declareVenta = new DeclareVenta(authPayload, this.billingService)

    declareVenta
      .execute(numericIdDto, declareVentaDto, sucursalId)
      .then((ventaDeclarada) => {
        CustomResponse.success({ res, data: ventaDeclarada })
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

    const [error, numericIdDto] = NumericIdDto.create(req.params)
    if (error !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload, sucursalId } = req

    const getVentaById = new GetVentaById(authPayload)

    getVentaById
      .execute(numericIdDto, sucursalId)
      .then((venta) => {
        CustomResponse.success({ res, data: venta })
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
}
