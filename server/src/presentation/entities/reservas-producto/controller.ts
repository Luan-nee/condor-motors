import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateReservasProductoDto } from '@/domain/dtos/entities/reservas-producto/create-reservasProducto.dto'
import { UpdateReservasProductosDto } from '@/domain/dtos/entities/reservas-producto/update-reservasProductos.dto'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { CreateReservasProducto } from '@/domain/use-cases/entities/ReservasProducto/create-reservasProducto.use-case'
import { GetReservasProductoById } from '@/domain/use-cases/entities/ReservasProducto/get-reservasProducto-by-id.use-case'
import { GetReservasProductos } from '@/domain/use-cases/entities/ReservasProducto/get-ReservasProductos.use-case'
import { UpdateReservasProductos } from '@/domain/use-cases/entities/ReservasProducto/update-reservasProductos.use-case'
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

  getById = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [error, numericIdDto] = NumericIdDto.create(req.params)

    if (error !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: 'Id Invalido' })
      return
    }

    const getReservasProductoById = new GetReservasProductoById()

    getReservasProductoById
      .execute(numericIdDto)
      .then((reserva) => {
        CustomResponse.success({ res, data: reserva })
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

    const [error, queriesDto] = QueriesDto.create(req.query)
    if (error !== undefined || queriesDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const getReservas = new GetReservasProductos()

    getReservas
      .execute(queriesDto)
      .then((reserva) => {
        CustomResponse.success({ res, data: reserva })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  update = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
    }

    const [paramErrors, numericIdDto] = NumericIdDto.create(req.params)

    if (paramErrors !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: 'Id INVAVLIDO' })
      return
    }

    const [updateReservasProductosError, updateReservasProductosDto] =
      UpdateReservasProductosDto.create(req.body)
    if (
      updateReservasProductosError !== undefined ||
      updateReservasProductosDto === undefined
    ) {
      CustomResponse.badRequest({ res, error: updateReservasProductosError })
      return
    }

    const updateReservasProductos = new UpdateReservasProductos()

    updateReservasProductos
      .execute(updateReservasProductosDto, numericIdDto)
      .then((reserva) => {
        const message = `la reserva con el id ${reserva.id} ha sido actualzado`
        CustomResponse.success({ res, message, data: reserva })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
