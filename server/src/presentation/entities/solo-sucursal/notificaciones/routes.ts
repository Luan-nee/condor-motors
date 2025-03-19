import { Router } from 'express'
import { NotificacionesController } from './controller'

export class NotificacionesRoutes {
  static get routes() {
    const router = Router()

    const notificacionesController = new NotificacionesController()

    router.get('/', notificacionesController.getAll)

    return router
  }
}
