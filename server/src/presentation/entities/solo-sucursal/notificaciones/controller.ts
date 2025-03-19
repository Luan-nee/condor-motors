import { CustomResponse } from '@/core/responses/custom.response'
import { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import type { Request, Response } from 'express'

export class NotificacionesController {
  getAll = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    if (req.sucursalId === undefined) {
      CustomResponse.badRequest({ res, error: 'ID de sucursal incorrecto' })
      return
    }

    const [error, queriesDto] = QueriesDto.create(req.query)

    if (error !== undefined || queriesDto === undefined) {
      CustomResponse.badRequest({ res, error })
    }

    // const {authPayload,sucursalId } = req;

    // const getNotificaciones =
  }
}
