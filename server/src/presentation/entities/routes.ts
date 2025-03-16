import { SucursalesRoutes } from '@presentation/entities/sucursales/routes'
import { EmpleadosRoutes } from '@presentation/entities/empleados/routes'
import { MarcasRoutes } from '@presentation/entities/marcas/routes'
import { Router } from 'express'
import { SoloSucursalRoutes } from '@/presentation/entities/solo-sucursal/routes'
import { EntitiesMiddleware } from '@/presentation/middlewares/entities.middleware'
// import { AdminAllRoutes } from '@/presentation/entities/solo-sucursal/admin-all.routes'
import { CategoriasRoutes } from './categorias/routes'
export class EntitiesRoutes {
  static get routes() {
    const router = Router()

    router.use('/sucursales', SucursalesRoutes.routes)
    router.use('/empleados', EmpleadosRoutes.routes)
    router.use('/marcas', MarcasRoutes.routes)
    router.use('/categorias', CategoriasRoutes.routes)
    // router.use('/admin', AdminAllRoutes.routes)

    router.use(
      '/:sucursalId',
      [EntitiesMiddleware.soloSucursal],
      SoloSucursalRoutes.routes
    )

    return router
  }
}
