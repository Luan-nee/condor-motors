import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateTransferenciaInventarioDto } from '@/domain/dtos/entities/TransferenciasInventario/create-transferenciaInventario.dto'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { GetTransferenciasInventariosById } from '@/domain/use-cases/entities/transferenciaInventario/get-transferenciaInventario-by-id.use-case'
import { GetTransferenciasInventarios } from '@/domain/use-cases/entities/transferenciaInventario/getAll-transferenciaInventario.use-case'
import type { Request, Response } from 'express'

export class TransferenciasInventarioController {
  create = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
    }

    const [error, createTransferenciaInventarioDto] =
      CreateTransferenciaInventarioDto.create(req.body)

    if (error !== undefined || createTransferenciaInventarioDto === undefined) {
      CustomResponse.badRequest({ res, error })
    }
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
}
