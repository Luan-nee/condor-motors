import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CancelVentaDto } from '@/domain/dtos/entities/ventas/cancel-venta.dto'
import { CreateVentaDto } from '@/domain/dtos/entities/ventas/create-venta.dto'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { CancelVenta } from '@/domain/use-cases/entities/ventas/cancel-venta.use-case'
import { CreateVenta } from '@/domain/use-cases/entities/ventas/create-venta.use-case'
import { GetVentaById } from '@/domain/use-cases/entities/ventas/get-venta-by-id.use-case'
import { GetVentas } from '@/domain/use-cases/entities/ventas/get-ventas.use-case'
import { GetInformacion } from '@/domain/use-cases/entities/ventas/getInformacion.use-case'
import type { Request, Response } from 'express'

export class VentasController {
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

    const [error, queriesDto] = QueriesDto.create(req.query)
    if (error !== undefined || queriesDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload, sucursalId } = req

    const getVentas = new GetVentas(authPayload)

    getVentas
      .execute(queriesDto, sucursalId)
      .then((ventas) => {
        CustomResponse.success({
          res,
          data: ventas.results,
          pagination: ventas.pagination,
          metadata: ventas.metadata
        })
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

    CustomResponse.notImplemented({ res })
  }

  cancelar = (req: Request, res: Response) => {
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

    const [error, cancelVentaDto] = CancelVentaDto.validate(req.body)
    if (error !== undefined || cancelVentaDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload, sucursalId } = req

    const cancelVenta = new CancelVenta(authPayload)

    cancelVenta
      .execute(numericIdDto, cancelVentaDto, sucursalId)
      .then((venta) => {
        CustomResponse.success({ res, data: venta })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  getInformacion = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
    }

    const getInformacion = new GetInformacion()

    getInformacion
      .execute()
      .then((informacion) => {
        CustomResponse.success({ res, data: informacion })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
