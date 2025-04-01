import { Router } from 'express'
import { ProductosController } from './controller'

export class ProductosRouter {
  static get routes() {
    const router = Router()

    const productosController = new ProductosController()

    router.get('/', productosController.detalles)

    return router
  }
}
