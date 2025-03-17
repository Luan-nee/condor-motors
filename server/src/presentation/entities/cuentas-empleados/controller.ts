import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { GetCuentaEmpleado } from '@/domain/use-cases/entities/cuentas-empleados/get-cuenta-empleado.use-case'
import type { Request, Response } from 'express'

export class CuentasEmpleadosController {
  getById = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [error, numericIdDto] = NumericIdDto.create(req.params)
    if (error !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload } = req

    const getCuentaEmpleado = new GetCuentaEmpleado(authPayload)

    getCuentaEmpleado
      .execute(numericIdDto)
      .then((cuentaEmpleado) => {
        CustomResponse.success({ res, data: cuentaEmpleado })
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

    CustomResponse.notImplemented({ res })
  }

  update = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    CustomResponse.notImplemented({ res })
  }

  delete = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    CustomResponse.notImplemented({ res })
  }
}
