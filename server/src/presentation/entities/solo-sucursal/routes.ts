import { Router } from 'express'
import { ProductosRoutes } from '@/presentation/entities/solo-sucursal/productos/routes'
import { InventariosRoutes } from '@/presentation/entities/solo-sucursal/inventarios/routes'

export class SoloSucursalRoutes {
  static get routes() {
    const router = Router()

    router.use('/productos', ProductosRoutes.routes)
    router.use('/inventarios', InventariosRoutes.routes)

    return router
  }
}
