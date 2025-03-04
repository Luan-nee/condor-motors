import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateEmpleadoDto } from '@/domain/dtos/entities/empleados/create-empleados.dto'
import { CreateEmpleado } from '@/domain/use-cases/entities/empleados/create-empleados.use-case'

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
}
