import { Router } from 'express'
import { ProductosController } from '@/presentation/entities/solo-sucursal/productos/controller'

export class ProductosRoutes {
  static get routes() {
    const router = Router()

    const productosController = new ProductosController()

    router.post('/', productosController.create)

    router.post('/:id', productosController.add)

    router.get('/:id', productosController.getById)

    router.get('/', productosController.getAll)

    router.patch('/:id', productosController.update)

    router.delete('/:id', productosController.delete)

    return router
  }
}
