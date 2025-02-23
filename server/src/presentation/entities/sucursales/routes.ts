import { SucursalesController } from '@presentation/entities/sucursales/controller'
import { AuthMiddleware } from '@presentation/middlewares/auth.middleware'
import { Router } from 'express'

export class sucursalesRoutes {
  static get routes() {
    const router = Router()

    const sucursalesController = new SucursalesController()

    router.post('/', AuthMiddleware.requests, sucursalesController.create)

    router.get('/:id', AuthMiddleware.requests, sucursalesController.getById)

    router.get('/', AuthMiddleware.requests, sucursalesController.getAll)

    return router
  }
}
