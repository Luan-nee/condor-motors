import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateClienteDto } from '@/domain/dtos/entities/clientes/create-cliente.dto'
import { UpdateClienteDto } from '@/domain/dtos/entities/clientes/update-cliente.dto'
import { NumericDocDto } from '@/domain/dtos/query-params/numeric-doc.dto'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { CreateCliente } from '@/domain/use-cases/entities/clientes/create-cliente.use-case'
import { GetClienteByDoc } from '@/domain/use-cases/entities/clientes/get-cliente-by-doc.use-case'
import { GetClienteById } from '@/domain/use-cases/entities/clientes/get-cliente-by-id.use-case'
import { GetClientes } from '@/domain/use-cases/entities/clientes/get-clientes.use-case'
import { UpdateCliente } from '@/domain/use-cases/entities/clientes/update-cliente.use-case'
import type { Request, Response } from 'express'

export class ClientesController {
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

  getByDoc = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [error, numericDocDto] = NumericDocDto.create(req.params)
    if (error !== undefined || numericDocDto === undefined) {
      CustomResponse.badRequest({ res, error: 'Numero de documento inválido' })
      return
    }

    const getClienteByDoc = new GetClienteByDoc()

    getClienteByDoc
      .execute(numericDocDto)
      .then((cliente) => {
        CustomResponse.success({ res, data: cliente })
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

    const getClientes = new GetClientes()

    getClientes
      .execute(queriesDto)
      .then((cliente) => {
        CustomResponse.success({ res, data: cliente })
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
      CustomResponse.badRequest({ res, error: 'Id INVALIDO' })
      return
    }

    const [updateClienteValidationError, updateClienteDto] =
      UpdateClienteDto.create(req.body)

    if (
      updateClienteValidationError !== undefined ||
      updateClienteDto === undefined
    ) {
      CustomResponse.badRequest({ res, error: updateClienteValidationError })
      return
    }

    const updateCliente = new UpdateCliente()

    updateCliente
      .execute(updateClienteDto, numericIdDto)
      .then((cliente) => {
        const message = `Cliente con el id: ${cliente.id} ha sido actualizado`
        CustomResponse.success({ res, message, data: cliente })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
