import { AuthMiddleware } from '@presentation/middlewares/auth.middleware'
import { Router } from 'express'
import { ProductosRoutes } from '@/presentation/entities/solo-sucursal/productos/routes'
import { InventariosRoutes } from '@/presentation/entities/solo-sucursal/inventarios/routes'

export class SoloSucursalRoutes {
  static get routes() {
    const router = Router()

    router.use('/productos', AuthMiddleware.requests, ProductosRoutes.routes)
    router.use(
      '/inventarios',
      AuthMiddleware.requests,
      InventariosRoutes.routes
    )

    return router
  }
}
