import { Router } from 'express'
import { ClientesController } from './controller'

export class ClientesRoutes {
  static get routes() {
    const router = Router()

    const clientesController = new ClientesController()

    router.post('/', clientesController.create)

    router.get('/:id', clientesController.getById)

    router.get('/doc/:doc', clientesController.getByDoc)

    return router
  }
}
