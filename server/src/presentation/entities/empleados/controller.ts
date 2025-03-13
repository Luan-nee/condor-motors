import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateEmpleadoDto } from '@/domain/dtos/entities/empleados/create-empleados.dto'
import { UpdateEmpleadoDto } from '@/domain/dtos/entities/empleados/ubdate-empleado.dto'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { CreateEmpleado } from '@/domain/use-cases/entities/empleados/create-empleados.use-case'
import { GetEmpleadoById } from '@/domain/use-cases/entities/empleados/get-empleado-by-id.use-case'
import { GetEmpleados } from '@/domain/use-cases/entities/empleados/get-empleados.use-case'
import { UpdateEmpleado } from '@/domain/use-cases/entities/empleados/update-empleado.use-case'

import type { Request, Response } from 'express'

export class EmpleadosController {
  create = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res, error: 'Invalid access token' })
      return
    }

    const [error, createEmpleadoDto] = CreateEmpleadoDto.create(req.body)
    if (error !== undefined || createEmpleadoDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    // const { authPayload } = req

    // const createEmpleado = new CreateEmpleado(authPayload)
    const createEmpleado = new CreateEmpleado()

    createEmpleado
      .execute(createEmpleadoDto)
      .then((empleado) => {
        CustomResponse.success({ res, data: empleado })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
  getById = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res, error: 'Solo personas autorizadas' })
      return
    }
    const [error, IdValor] = NumericIdDto.create(req.params)

    if (error !== undefined || IdValor === undefined) {
      CustomResponse.badRequest({ res, error: 'Id no valido' })
      return
    }
    const { authPayload } = req
    const getEmpleadoById = new GetEmpleadoById(authPayload)

    getEmpleadoById
      .execute(IdValor)
      .then((empleado) => {
        CustomResponse.success({ res, data: empleado })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  getAll = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res, error: 'Esta Informacion es privada' })
      return
    }
    const [error, queriesDto] = QueriesDto.create(req.query)

    if (error !== undefined || queriesDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload } = req
    const getEmpleados = new GetEmpleados(authPayload)

    getEmpleados
      .execute(queriesDto)
      .then((empleado) => {
        CustomResponse.success({ res, data: empleado })
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
    const [paramErrors, numericIdDto] = NumericIdDto.create(req.params)
    if (paramErrors !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: 'Id Incorrecto' })
      return
    }

    const [updateEmpleadoValidationError, updateEmpleadoDto] =
      UpdateEmpleadoDto.create(req.body)

    if (
      updateEmpleadoValidationError !== undefined ||
      updateEmpleadoDto === undefined
    ) {
      CustomResponse.badRequest({ res, error: updateEmpleadoValidationError })
      return
    }

    const updateEmpleado = new UpdateEmpleado()
    updateEmpleado
      .execute(updateEmpleadoDto, numericIdDto)
      .then((empleado) => {
        const message = `Sucursal con id ${empleado.id} ha sido actualizada`
        CustomResponse.success({ res, message, data: empleado })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
