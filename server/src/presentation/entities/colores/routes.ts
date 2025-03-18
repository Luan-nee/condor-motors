import { Router } from 'express'
import { ColoresController } from './controller'

export class ColoresRoutes {
  static get routes() {
    const router = Router()
    const coloresController = new ColoresController()
    router.get('/', coloresController.getAll)
    return router
  }
}
