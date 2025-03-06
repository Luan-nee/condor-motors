import { SucursalesRoutes } from '@presentation/entities/sucursales/routes'
import { EmpleadosRoutes } from '@presentation/entities/empleados/routes'
import { MarcasRoutes } from '@presentation/entities/marcas/routes'
import { AuthMiddleware } from '@presentation/middlewares/auth.middleware'
import { Router } from 'express'
import { SoloSucursalRoutes } from '@/presentation/entities/solo-sucursal/routes'
import { EntitiesMiddleware } from '@/presentation/middlewares/entities.middleware'

export class EntitiesRoutes {
  static get routes() {
    const router = Router()

    router.use('/sucursales', AuthMiddleware.requests, SucursalesRoutes.routes)
    router.use('/empleados', AuthMiddleware.requests, EmpleadosRoutes.routes)
    router.use('/marcas', AuthMiddleware.requests, MarcasRoutes.routes)

    router.use(
      '/:sucursalId',
      [AuthMiddleware.requests, EntitiesMiddleware.soloSucursal],
      SoloSucursalRoutes.routes
    )

    return router
  }
}
