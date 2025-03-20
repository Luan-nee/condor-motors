import { CustomResponse } from '@/core/responses/custom.response'
import { CreateClienteDto } from '@/domain/dtos/entities/clientes/create-cliente.dto'
import type { Request, Response } from 'express'

export class ClientesController {
  validarDatos = (num1: number, num2: number, num3: number, num4: number) => {
    if ((num1 === 1 || num2 === 1) && (num3 === 1 || num4 === 1)) {
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
    const valid2 = createClienteDto.dni === undefined ? 1 : 2
    const valid11 = createClienteDto.razonSocial === undefined ? 1 : 2
    const valid22 = createClienteDto.ruc === undefined ? 1 : 2

    if (!this.validarDatos(valid1, valid2, valid11, valid22)) {
      CustomResponse.badRequest({
        res,
        error: 'Nombre y DNI  o  Razon social y ruc deben estar disponibles '
      })
      // return;
    }
    // const {authPayload} = req;
  }
}
