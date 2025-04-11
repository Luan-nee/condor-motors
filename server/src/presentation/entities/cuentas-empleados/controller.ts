import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { UpdateCuentaEmpleadoDto } from '@/domain/dtos/entities/cuentas-empleados/update-cuenta-empleado.dto'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { DeleteCuentaEmpleado } from '@/domain/use-cases/entities/cuentas-empleados/delete-cuenta-empleado.use-case'
import { GetCuentaEmpleado } from '@/domain/use-cases/entities/cuentas-empleados/get-cuenta-empleado.use-case'
import { GetCuentasEmpleados } from '@/domain/use-cases/entities/cuentas-empleados/get-cuentas-empleados.use-case'
import { UpdateCuentaEmpleado } from '@/domain/use-cases/entities/cuentas-empleados/update-cuenta-empleado.use-case'
import { RegisterUserDto } from '@domain/dtos/auth/register-user.dto'
import { RegisterUser } from '@domain/use-cases/auth/register-user.use-case'
import type { Encryptor, TokenAuthenticator } from '@/types/interfaces'
import type { Request, Response } from 'express'

export class CuentasEmpleadosController {
  constructor(
    private readonly tokenAuthenticator: TokenAuthenticator,
    private readonly encryptor: Encryptor
  ) {}

  create = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [error, registerUserDto] = RegisterUserDto.create(req.body)
    if (error !== undefined || registerUserDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload } = req

    const registerUser = new RegisterUser(
      this.tokenAuthenticator,
      this.encryptor,
      authPayload
    )

    registerUser
      .execute(registerUserDto)
      .then((user) => {
        CustomResponse.success({
          res,
          data: user.data
        })
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

    const { authPayload } = req

    const getCuentasEmpleados = new GetCuentasEmpleados(authPayload)

    getCuentasEmpleados
      .execute()
      .then((cuentasEmpleados) => {
        CustomResponse.success({ res, data: cuentasEmpleados })
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
      CustomResponse.badRequest({ res, error: paramErrors })
      return
    }

    const [error, updateCuentaEmpleadoDto] = UpdateCuentaEmpleadoDto.create(
      req.body
    )
    if (error !== undefined || updateCuentaEmpleadoDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload } = req

    const updateCuentaEmpleado = new UpdateCuentaEmpleado(
      this.tokenAuthenticator,
      this.encryptor,
      authPayload
    )

    updateCuentaEmpleado
      .execute(updateCuentaEmpleadoDto, numericIdDto)
      .then((cuentaEmpleado) => {
        CustomResponse.success({ res, data: cuentaEmpleado })
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

    const [paramErrors, numericIdDto] = NumericIdDto.create(req.params)
    if (paramErrors !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: paramErrors })
      return
    }

    const { authPayload } = req

    const deleteCuentaEmpleado = new DeleteCuentaEmpleado(authPayload)

    deleteCuentaEmpleado
      .execute(numericIdDto)
      .then((cuentaEmpleado) => {
        CustomResponse.success({ res, data: cuentaEmpleado })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
