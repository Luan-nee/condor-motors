import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateTransferenciaInvDto } from '@/domain/dtos/entities/transferencias-inventario/create-transferencia-inventario.dto'
import { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { CreateTransferenciaInv } from '@/domain/use-cases/entities/transferencias-inventario/create-transferenciaInventario.use-case'
import { GetTransferenciasInventarios } from '@/domain/use-cases/entities/transferencias-inventario/getAll-transferenciaInventario.use-case'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { GetTransferenciasInventariosById } from '@/domain/use-cases/entities/transferencias-inventario/get-transferenciaInventario-by-id.use-case'
import type { Request, Response } from 'express'
import { EnviarTransferenciaInvDto } from '@/domain/dtos/entities/transferencias-inventario/enviar-transferencia-inventario.dto'
import { EnviarTransferenciaInventario } from '@/domain/use-cases/entities/transferencias-inventario/enviar-transferencia-inventario.use-case'
import { RecibirTransferenciaInventario } from '@/domain/use-cases/entities/transferencias-inventario/recibir-transferencia-inventario.use-case'
import { DeleteTransferenciaInventario } from '@/domain/use-cases/entities/transferencias-inventario/delete-transferencia-inventario.use-case'

export class TransferenciasInventarioController {
  create = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [error, createTransferenciaInvDto] = CreateTransferenciaInvDto.create(
      req.body
    )
    if (error !== undefined || createTransferenciaInvDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload } = req

    const createTransferenciaInv = new CreateTransferenciaInv(authPayload)

    createTransferenciaInv
      .execute(createTransferenciaInvDto)
      .then((transferenciaInv) => {
        CustomResponse.success({ res, data: transferenciaInv })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  enviar = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [paramErrors, numericIdDto] = NumericIdDto.create(req.params)
    if (paramErrors !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: paramErrors })
      return
    }

    const [error, enviarTransferenciaInvDto] = EnviarTransferenciaInvDto.create(
      req.body
    )
    if (error !== undefined || enviarTransferenciaInvDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload } = req

    const enviarTransferenciaInv = new EnviarTransferenciaInventario(
      authPayload
    )

    enviarTransferenciaInv
      .execute(numericIdDto, enviarTransferenciaInvDto)
      .then((transferenciaInv) => {
        CustomResponse.success({ res, data: transferenciaInv })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  recibir = (req: Request, res: Response) => {
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

    const recibirTransferenciaInv = new RecibirTransferenciaInventario(
      authPayload
    )

    recibirTransferenciaInv
      .execute(numericIdDto)
      .then((transferenciaInv) => {
        CustomResponse.success({ res, data: transferenciaInv })
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

    const getTransferenciaInventarioById =
      new GetTransferenciasInventariosById()

    getTransferenciaInventarioById
      .execute(numericIdDto)
      .then((transferencia) => {
        CustomResponse.success({ res, data: transferencia })
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

    const getTransferenciasInventarios = new GetTransferenciasInventarios()

    getTransferenciasInventarios
      .execute(queriesDto)
      .then((transInventario) => {
        CustomResponse.success({ res, data: transInventario })
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

    CustomResponse.notImplemented({ res })
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

    const deleteTransferenciaInv = new DeleteTransferenciaInventario(
      authPayload
    )

    deleteTransferenciaInv
      .execute(numericIdDto)
      .then((transferenciaInv) => {
        CustomResponse.success({ res, data: transferenciaInv })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
