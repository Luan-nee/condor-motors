import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateEmpleadoDto } from '@/domain/dtos/entities/empleados/create-empleado.dto'
import { UpdateEmpleadoDto } from '@/domain/dtos/entities/empleados/update-empleado.dto'
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
      CustomResponse.invalidAccessToken({ res })
      return
    }

    const [error, createEmpleadoDto] = CreateEmpleadoDto.create(req.body)
    if (error !== undefined || createEmpleadoDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload } = req

    const createEmpleado = new CreateEmpleado(authPayload)

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
      CustomResponse.invalidAccessToken({ res })
      return
    }

    const [error, numericIdDto] = NumericIdDto.create(req.params)
    if (error !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload } = req

    const getEmpleadoById = new GetEmpleadoById(authPayload)

    getEmpleadoById
      .execute(numericIdDto)
      .then((empleado) => {
        CustomResponse.success({ res, data: empleado })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  getAll = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.invalidAccessToken({ res })
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
      .then((empleados) => {
        CustomResponse.success({
          res,
          data: empleados.results,
          pagination: empleados.pagination,
          metadata: empleados.metadata
        })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  update = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.invalidAccessToken({ res })
      return
    }

    const [paramErrors, numericIdDto] = NumericIdDto.create(req.params)
    if (paramErrors !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: paramErrors })
      return
    }

    const [error, updateEmpleadoDto] = UpdateEmpleadoDto.create(req.body)
    if (error !== undefined || updateEmpleadoDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload } = req

    const updateEmpleado = new UpdateEmpleado(authPayload)

    updateEmpleado
      .execute(updateEmpleadoDto, numericIdDto)
      .then((empleado) => {
        CustomResponse.success({ res, data: empleado })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  // delete = (req: Request, res: Response) => {
  //   if (req.authPayload === undefined) {
  //     CustomResponse.invalidAccessToken({ res })
  //     return
  //   }

  //   const [error, numericIdDto] = NumericIdDto.create(req.params)
  //   if (error !== undefined || numericIdDto === undefined) {
  //     CustomResponse.badRequest({ res, error: 'el ID ingresado no es valido' })
  //     return
  //   }

  //   const deleteEmpleado = new DeleteEmpleado()

  //   deleteEmpleado
  //     .execute(numericIdDto)
  //     .then((empleado) => {
  //       const message = empleado.activo
  //         ? `Empleado con el id '${empleado.id}' eliminado`
  //         : `Empleado con el id '${empleado.id}' a sido dado de baja`
  //       CustomResponse.success({ res, message, data: empleado })
  //     })
  //     .catch((error: unknown) => {
  //       handleError(error, res)
  //     })
  // }

  // Método para activar empleado
  // activar = (req: Request, res: Response) => {
  //   if (req.authPayload === undefined) {
  //     CustomResponse.invalidAccessToken({ res })
  //     return
  //   }

  //   const [error, numericIdDto] = NumericIdDto.create(req.params)

  //   if (error !== undefined || numericIdDto === undefined) {
  //     CustomResponse.badRequest({ res, error: 'El ID ingresado no es válido' })
  //     return
  //   }

  //   // Usar el caso de uso de actualización con activo=true
  //   const updateEmpleado = new UpdateEmpleado()
  //   const updateData = { activo: true }

  //   updateEmpleado
  //     .execute(updateData, numericIdDto)
  //     .then((empleado) => {
  //       const message = `Empleado con id ${empleado.id} ha sido activado`
  //       CustomResponse.success({ res, message, data: empleado })
  //     })
  //     .catch((error: unknown) => {
  //       handleError(error, res)
  //     })
  // }

  // Método para desactivar empleado
  // desactivar = (req: Request, res: Response) => {
  //   if (req.authPayload === undefined) {
  //     CustomResponse.invalidAccessToken({ res })
  //     return
  //   }

  //   const [error, numericIdDto] = NumericIdDto.create(req.params)

  //   if (error !== undefined || numericIdDto === undefined) {
  //     CustomResponse.badRequest({ res, error: 'El ID ingresado no es válido' })
  //     return
  //   }

  //   // Usar el caso de uso de actualización con activo=false
  //   const updateEmpleado = new UpdateEmpleado()
  //   const updateData = { activo: false }

  //   updateEmpleado
  //     .execute(updateData, numericIdDto)
  //     .then((empleado) => {
  //       const message = `Empleado con id ${empleado.id} ha sido desactivado`
  //       CustomResponse.success({ res, message, data: empleado })
  //     })
  //     .catch((error: unknown) => {
  //       handleError(error, res)
  //     })
  // }
}
