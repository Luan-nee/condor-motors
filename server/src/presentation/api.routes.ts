import { AuthRoutes } from '@presentation/auth/routes'
import { Router } from 'express'
import { EntitiesRoutes } from './entities/router'

export class ApiRoutes {
  static get routes() {
    const router = Router()

    router.use('/auth', AuthRoutes.routes)

    router.use(EntitiesRoutes.routes)

    return router
  }
}
