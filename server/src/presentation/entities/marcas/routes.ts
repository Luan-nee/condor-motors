import { Router } from 'express'
import { MarcasController } from './controller'

export class MarcasRoutes {
  static get routes() {
    const router = Router()
    const controller = new MarcasController()

    router.get('/', controller.getAll)
    router.get('/:id', controller.getById)
    router.post('/', controller.create)
    router.put('/:id', controller.update)
    router.delete('/:id', controller.delete)

    return router
  }
}
