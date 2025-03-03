import { sucursalesRoutes } from '@presentation/entities/sucursales/routes'
import { ChambeadorRoutes } from '@presentation/entities/empleados/routes'
import { AuthMiddleware } from '@presentation/middlewares/auth.middleware'
import { Router } from 'express'

export class EntitiesRoutes {
  static get routes() {
    const router = Router()

    router.use('/sucursales', AuthMiddleware.requests, sucursalesRoutes.routes)
    router.use('/empleado', AuthMiddleware.requests, ChambeadorRoutes.routes)
    return router
  }
}
