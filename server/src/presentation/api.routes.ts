import { AuthRoutes } from '@presentation/auth/routes'
import { EntitiesRoutes } from '@presentation/entities/routes'
import { Router } from 'express'
import { AuthMiddleware } from '@/presentation/middlewares/auth.middleware'

export class ApiRoutes {
  static get routes() {
    const router = Router()

    router.use('/auth', AuthRoutes.routes)

    router.use([AuthMiddleware.requests], EntitiesRoutes.routes)

    return router
  }
}
