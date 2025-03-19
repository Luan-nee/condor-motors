import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { DeleteNotificacion } from '@/domain/use-cases/entities/notificaciones/delete-notificaciones.use-case'
import { GetNotificaciones } from '@/domain/use-cases/entities/notificaciones/get-notificaciones.use-case'
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
      return
    }

    const { sucursalId } = req

    const getNotificaciones = new GetNotificaciones()

    getNotificaciones
      .execute(sucursalId)
      .then((notificacion) => {
        CustomResponse.success({ res, data: notificacion })
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
    const [error, numericIdDto] = NumericIdDto.create(req.params)

    if (error !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: 'ID invalido' })
      return
    }
    const deleteNotificacion = new DeleteNotificacion()

    deleteNotificacion
      .execute(numericIdDto)
      .then((notificacion) => {
        const message = `Notificacion con el ID '${notificacion.id} eliminado'`
        CustomResponse.success({ res, message, data: notificacion })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
