import { AuthMiddleware } from '@presentation/middlewares/auth.middleware'
import { Router } from 'express'
import { SucursalesController } from './sucursales/controller'

export class EntitiesRoutes {
  static get routes() {
    const router = Router()

    const sucursalesController = new SucursalesController()

    router.post(
      '/sucursales',
      AuthMiddleware.requests,
      sucursalesController.create
    )

    return router
  }
}
