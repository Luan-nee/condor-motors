import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateSucursalDto } from '@/domain/dtos/entities/sucursales/create-sucursal.dto'
import { UpdateSucursalDto } from '@/domain/dtos/entities/sucursales/update-sucursal.dto'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { CreateSucursal } from '@/domain/use-cases/entities/sucursales/create-sucursal.use-case'
import { DeleteSucursal } from '@/domain/use-cases/entities/sucursales/delete-sucursal.use-case'
import { GetSucursalById } from '@/domain/use-cases/entities/sucursales/get-sucursal-by-id.use-case'
import { GetSucursales } from '@/domain/use-cases/entities/sucursales/get-sucursales.use-case'
import type { Request, Response } from 'express'

export class SucursalesController {
  // eslint-disable-next-line @typescript-eslint/class-methods-use-this
  create = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res, error: 'Invalid access token' })
      return
    }

    const [error, createSucursalDto] = CreateSucursalDto.create(req.body)
    if (error !== undefined || createSucursalDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const createSucursal = new CreateSucursal()

    createSucursal
      .execute(createSucursalDto)
      .then((sucursal) => {
        CustomResponse.success({ res, data: sucursal })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  // eslint-disable-next-line @typescript-eslint/class-methods-use-this
  getById = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res, error: 'Invalid access token' })
      return
    }

    const [error, numericIdDto] = NumericIdDto.create(req.params)
    if (error !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: 'Id inválido' })
      return
    }

    const getSucursalById = new GetSucursalById()

    getSucursalById
      .execute(numericIdDto)
      .then((sucursal) => {
        CustomResponse.success({ res, data: sucursal })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  // eslint-disable-next-line @typescript-eslint/class-methods-use-this
  getAll = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res, error: 'Invalid access token' })
      return
    }

    const [error, queriesDto] = QueriesDto.create(req.query)
    if (error !== undefined || queriesDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const getSucursales = new GetSucursales()

    getSucursales
      .execute(queriesDto)
      .then((sucursales) => {
        CustomResponse.success({ res, data: sucursales })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  // eslint-disable-next-line @typescript-eslint/class-methods-use-this
  update = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res, error: 'Invalid access token' })
      return
    }

    const [paramErrors, numericIdDto] = NumericIdDto.create(req.params)
    if (paramErrors !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: 'Id inválido' })
      return
    }

    const [updateSucursalValidationError, createSucursalDto] =
      UpdateSucursalDto.create(req.body)
    if (
      updateSucursalValidationError !== undefined ||
      createSucursalDto === undefined
    ) {
      CustomResponse.badRequest({ res, error: updateSucursalValidationError })
      return
    }

    // eslint-disable-next-line no-console
    console.log(createSucursalDto)

    CustomResponse.notImplemented({ res })
  }

  // eslint-disable-next-line @typescript-eslint/class-methods-use-this
  delete = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res, error: 'Invalid access token' })
      return
    }

    const [error, numericIdDto] = NumericIdDto.create(req.params)
    if (error !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: 'Id inválido' })
      return
    }

    const deleteSucursal = new DeleteSucursal()

    deleteSucursal
      .execute(numericIdDto)
      .then((sucursal) => {
        const message = `Sucursal con id '${sucursal.id}' eliminada`

        CustomResponse.success({ res, message, data: sucursal })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
