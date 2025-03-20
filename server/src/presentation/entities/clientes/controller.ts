import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateClienteDto } from '@/domain/dtos/entities/clientes/create-cliente.dto'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { CreateCliente } from '@/domain/use-cases/entities/clientes/create-cliente.use-case'
import { GetClienteById } from '@/domain/use-cases/entities/clientes/get-cliente-by-id.use-case'
import type { Request, Response } from 'express'

export class ClientesController {
  validarDatos = (num1: number, num2: number, num3: number, num4: number) => {
    if ((num1 === 2 && num2 === 2) || (num3 === 2 && num4 === 2)) {
      return true
    }
    return false
  }
  create = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [error, createClienteDto] = CreateClienteDto.create(req.body)
    if (error !== undefined || createClienteDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const valid1 = createClienteDto.nombresApellidos === undefined ? 1 : 2
    const valid11 = createClienteDto.razonSocial === undefined ? 1 : 2

    if (valid1 === 1 && valid11 === 1) {
      CustomResponse.badRequest({
        res,
        error: 'Nombre o  Razon social  deben estar disponibles '
      })
    }
    // const {authPayload} = req;

    const createCliente = new CreateCliente()

    createCliente
      .execute(createClienteDto)
      .then((cliente) => {
        CustomResponse.success({ res, data: cliente })
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

    const getClienteById = new GetClienteById()

    getClienteById
      .execute(numericIdDto)
      .then((cliente) => {
        CustomResponse.success({ res, data: cliente })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
