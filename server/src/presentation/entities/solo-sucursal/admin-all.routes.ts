import { Router } from 'express'
import { ProductosController } from '@/presentation/entities/solo-sucursal/productos/controller'

export class AdminAllRoutes {
  static get routes() {
    const router = Router()

    router.get('/productos', new ProductosController().all)

    return router
  }
}
