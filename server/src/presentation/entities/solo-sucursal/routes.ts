import { AuthMiddleware } from '@presentation/middlewares/auth.middleware'
import { Router } from 'express'
import { ProductosRoutes } from '@/presentation/entities/solo-sucursal/productos/routes'

export class SoloSucursalRoutes {
  static get routes() {
    const router = Router()

    router.use('/productos', AuthMiddleware.requests, ProductosRoutes.routes)

    return router
  }
}
