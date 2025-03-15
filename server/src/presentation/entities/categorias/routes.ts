import { Router } from 'express'

export class CategoriasRoutes {
  static get routes() {
    const router = Router()

    router.post('/')

    return router
  }
}
