import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateProformaVentaDto } from '@/domain/dtos/entities/proformas-venta/create-proforma-venta.dto'
import { UpdateProformaVentaDto } from '@/domain/dtos/entities/proformas-venta/update-proforma-venta.dto'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { CreateProformaVenta } from '@/domain/use-cases/entities/proformas-venta/create-proforma-venta.use-case'
import { GetProformasVenta } from '@/domain/use-cases/entities/proformas-venta/get-proformas-venta.use-case'
import { UpdateProformaVenta } from '@/domain/use-cases/entities/proformas-venta/update-proforma-venta.use-case'
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

    const [error, queriesDto] = QueriesDto.create(req.query)
    if (error !== undefined || queriesDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload, sucursalId } = req

    const getProformasVenta = new GetProformasVenta(authPayload)

    getProformasVenta
      .execute(queriesDto, sucursalId)
      .then((proformasVenta) => {
        CustomResponse.success({ res, data: proformasVenta })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
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

    const [paramErrors, numericIdDto] = NumericIdDto.create(req.params)
    if (paramErrors !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: paramErrors })
      return
    }

    const [error, updateProformaVentaDto] = UpdateProformaVentaDto.validate(
      req.body
    )
    if (error !== undefined || updateProformaVentaDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload, sucursalId } = req

    const updateProformaVenta = new UpdateProformaVenta(authPayload)

    updateProformaVenta
      .execute(numericIdDto, updateProformaVentaDto, sucursalId)
      .then((proformaVenta) => {
        CustomResponse.success({ res, data: proformaVenta })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
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
