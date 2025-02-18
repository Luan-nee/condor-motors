import { AuthRoutes } from '@presentation/auth/routes'
import { Router } from 'express'

export class ApiRoutes {
  static get routes() {
    const router = Router()

    router.use('/auth', AuthRoutes.routes)

    return router
  }
}
