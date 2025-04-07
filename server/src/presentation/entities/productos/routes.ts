import { Router } from 'express'
import { ProductosController } from './controller'
import { AccessControlMiddleware } from '@/presentation/middlewares/access-control.middleware'
import { permissionCodes } from '@/consts'

export class ProductosRouter {
  static get routes() {
    const router = Router()

    const productosController = new ProductosController()

    router.get('/:id/detalles', productosController.detalles)

    router.get('/reporte', productosController.getReporteProducto)

    router.get(
      '/',
      [
        AccessControlMiddleware.requests([permissionCodes.productos.getRelated])
      ],
      productosController.getAll
    )

    return router
  }
}
