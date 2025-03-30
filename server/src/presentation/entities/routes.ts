import { SucursalesRoutes } from '@/presentation/entities/sucursales/routes'
import { EmpleadosRoutes } from '@/presentation/entities/empleados/routes'
import { MarcasRoutes } from '@/presentation/entities/marcas/routes'
import { Router } from 'express'
import { SoloSucursalRoutes } from '@/presentation/entities/solo-sucursal/routes'
import { EntitiesMiddleware } from '@/presentation/middlewares/entities.middleware'
import { CategoriasRoutes } from '@/presentation/entities/categorias/routes'
import { RolesCuentasRoutes } from '@/presentation/entities/roles-cuentas/routes'
import { CuentasEmpleadosRoutes } from '@/presentation/entities/cuentas-empleados/routes'
import { ColoresRoutes } from '@/presentation/entities/colores/routes'
import { ClientesRoutes } from './clientes/routes'
import { ReservasProductoRoutes } from '@/presentation/entities/reservas-producto/routes'
import { TransferenciasInventarioRoutes } from '@/presentation/entities/transferencias-inventario/routes'
import { EstadisticaRouter } from './estadisticas/routes'

export class EntitiesRoutes {
  static get routes() {
    const router = Router()

    router.use('/sucursales', SucursalesRoutes.routes)
    router.use('/empleados', EmpleadosRoutes.routes)
    router.use('/marcas', MarcasRoutes.routes)
    router.use('/categorias', CategoriasRoutes.routes)
    router.use('/rolescuentas', RolesCuentasRoutes.routes)
    router.use('/clientes', ClientesRoutes.routes)
    router.use('/reservasproductos', ReservasProductoRoutes.routes)
    router.use('/cuentasempleados', CuentasEmpleadosRoutes.routes)
    router.use('/colores', ColoresRoutes.routes)
    router.use('/estadisticas', EstadisticaRouter.routes)
    router.use(
      '/transferenciasinventario',
      TransferenciasInventarioRoutes.routes
    )

    router.use(
      '/:sucursalId',
      [EntitiesMiddleware.soloSucursal],
      SoloSucursalRoutes.routes
    )

    return router
  }
}
