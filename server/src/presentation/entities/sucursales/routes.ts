import { SucursalesController } from '@presentation/entities/sucursales/controller'
import { Router } from 'express'

export class SucursalesRoutes {
  static get routes() {
    const router = Router()

    const sucursalesController = new SucursalesController()

    router.post('/', sucursalesController.create)

    router.get('/:id', sucursalesController.getById)

    router.get('/', sucursalesController.getAll)

    router.patch('/:id', sucursalesController.update)

    router.delete('/:id', sucursalesController.delete)

    return router
  }
}
