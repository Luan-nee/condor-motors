import { AuthRoutes } from '@presentation/auth/routes'
import { EntitiesRoutes } from '@presentation/entities/routes'
import { Router } from 'express'

export class ApiRoutes {
  static get routes() {
    const router = Router()

    router.use('/auth', AuthRoutes.routes)

    router.use(EntitiesRoutes.routes)

    return router
  }
}
