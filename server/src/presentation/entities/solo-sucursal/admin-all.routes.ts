import { AuthMiddleware } from '@presentation/middlewares/auth.middleware'
import { Router } from 'express'
import { ProductosController } from './productos/controller'

export class AdminAllRoutes {
  static get routes() {
    const router = Router()

    router.get(
      '/productos',
      AuthMiddleware.requests,
      new ProductosController().all
    )

    return router
  }
}
