import { Router } from 'express'
import { ProductosController } from './controller'

export class ProductosRoutes {
  static get routes() {
    const router = Router()

    const productosController = new ProductosController()

    router.post('/', productosController.create)

    router.get('/:id', productosController.getById)

    // router.get('/', productosController.getAll)

    // router.patch('/:id', productosController.update)

    // router.delete('/:id', productosController.delete)

    return router
  }
}
