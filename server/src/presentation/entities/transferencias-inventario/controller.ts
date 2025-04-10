import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateTransferenciaInvDto } from '@/domain/dtos/entities/transferencias-inventario/create-transferencia-inventario.dto'
import { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { CreateTransferenciaInv } from '@/domain/use-cases/entities/transferencias-inventario/create-transferenciaInventario.use-case'
import { GetTransferenciasInventarios } from '@/domain/use-cases/entities/transferencias-inventario/get-transferencias-inventarios.use-case'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { GetTransferenciasInventariosById } from '@/domain/use-cases/entities/transferencias-inventario/get-transferenciaInventario-by-id.use-case'
import type { Request, Response } from 'express'
import { EnviarTransferenciaInvDto } from '@/domain/dtos/entities/transferencias-inventario/enviar-transferencia-inventario.dto'
import { EnviarTransferenciaInventario } from '@/domain/use-cases/entities/transferencias-inventario/enviar-transferencia-inventario.use-case'
import { RecibirTransferenciaInventario } from '@/domain/use-cases/entities/transferencias-inventario/recibir-transferencia-inventario.use-case'
import { DeleteTransferenciaInventario } from '@/domain/use-cases/entities/transferencias-inventario/delete-transferencia-inventario.use-case'
import { CancelarTransferenciaInventario } from '@/domain/use-cases/entities/transferencias-inventario/cancelar-transferencia-inventario.use-case'
import { AddItemTransferenciaInvDto } from '@/domain/dtos/entities/transferencias-inventario/add-item-transferencia-inventario.dto'
import { AddItemTransferenciaInv } from '@/domain/use-cases/entities/transferencias-inventario/add-item-transferencia-inventario.use-case'
import { DoubleNumericIdDto } from '@/domain/dtos/query-params/double-numeric.-id.dto'
import { UpdateItemTransferenciaInv } from '@/domain/use-cases/entities/transferencias-inventario/update-item-transferencia-inventario.use-case'
import { UpdateItemTransferenciaInvDto } from '@/domain/dtos/entities/transferencias-inventario/update-item-transferencia-inventario.dto'
import { RemoveItemTransferenciaInv } from '@/domain/use-cases/entities/transferencias-inventario/remove-item-transferencia-inventario.use-case'
import { CompararTransferenciaInventario } from '@/domain/use-cases/entities/transferencias-inventario/comparar-transferencia-inventario.use-case'
import { CompararTransferenciaInvDtoValidator } from '@/domain/dtos/entities/transferencias-inventario/comparar-transferencia-inventario.dto'

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

  cancelar = (req: Request, res: Response) => {
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

    const cancelar = new CancelarTransferenciaInventario(authPayload)

    cancelar
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
      .then((transferenciasInvs) => {
        CustomResponse.success({
          res,
          data: transferenciasInvs.results,
          metadata: transferenciasInvs.metadata,
          pagination: transferenciasInvs.pagination
        })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  addItems = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [paramErrors, numericIdDto] = NumericIdDto.create(req.params)
    if (paramErrors !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: paramErrors })
      return
    }

    const [error, addItemTransferenciaInvDto] =
      AddItemTransferenciaInvDto.create(req.body)
    if (error !== undefined || addItemTransferenciaInvDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload } = req

    const addItemTransferenciaInv = new AddItemTransferenciaInv(authPayload)

    addItemTransferenciaInv
      .execute(numericIdDto, addItemTransferenciaInvDto)
      .then((transferenciaInv) => {
        CustomResponse.success({ res, data: transferenciaInv })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  updateItems = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [paramErrors, doubleNumericIdDto] = DoubleNumericIdDto.create(
      req.params
    )
    if (paramErrors !== undefined || doubleNumericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: paramErrors })
      return
    }

    const [error, updateItemTransferenciaInvDto] =
      UpdateItemTransferenciaInvDto.create(req.body)
    if (error !== undefined || updateItemTransferenciaInvDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload } = req

    const updateItemTransferenciaInv = new UpdateItemTransferenciaInv(
      authPayload
    )

    updateItemTransferenciaInv
      .execute(doubleNumericIdDto, updateItemTransferenciaInvDto)
      .then((transferenciaInv) => {
        CustomResponse.success({ res, data: transferenciaInv })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  removeItems = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [paramErrors, doubleNumericIdDto] = DoubleNumericIdDto.create(
      req.params
    )
    if (paramErrors !== undefined || doubleNumericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: paramErrors })
      return
    }

    const { authPayload } = req

    const removeItemTransferenciaInv = new RemoveItemTransferenciaInv(
      authPayload
    )

    removeItemTransferenciaInv
      .execute(doubleNumericIdDto)
      .then((transferenciaInv) => {
        CustomResponse.success({ res, data: transferenciaInv })
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

  comparar = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [paramErrors, numericIdDto] = NumericIdDto.create(req.params)
    if (paramErrors !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: paramErrors })
      return
    }

    const [error, compararTransferenciaInvDto] =
      CompararTransferenciaInvDtoValidator.create(req.body)
    if (error !== undefined || compararTransferenciaInvDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload } = req

    const compararTransferenciaInv = new CompararTransferenciaInventario(
      authPayload
    )

    compararTransferenciaInv
      .execute(numericIdDto, compararTransferenciaInvDto)
      .then((comparacion) => {
        CustomResponse.success({ res, data: comparacion })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
