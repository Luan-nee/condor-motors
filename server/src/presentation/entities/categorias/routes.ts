import { Router } from 'express'
import { CategoriasController } from './controller'

export class CategoriasRoutes {
  static get routes() {
    const router = Router()
    const categoriasController = new CategoriasController()
    router.post('/', categoriasController.create)

    return router
  }
}
