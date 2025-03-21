import { Router } from 'express'
import { ProductosRoutes } from '@/presentation/entities/solo-sucursal/productos/routes'
import { InventariosRoutes } from '@/presentation/entities/solo-sucursal/inventarios/routes'
import { ProformasVentaRoutes } from '@/presentation/entities/solo-sucursal/proformas-venta/routes'
import { NotificacionesRoutes } from './notificaciones/routes'
import { VentasRoutes } from '@/presentation/entities/solo-sucursal/ventas/routes'

export class SoloSucursalRoutes {
  static get routes() {
    const router = Router()

    router.use('/productos', ProductosRoutes.routes)
    router.use('/inventarios', InventariosRoutes.routes)
    router.use('/proformasventa', ProformasVentaRoutes.routes)
    router.use('/ventas', VentasRoutes.routes)
    router.use('/notificaciones', NotificacionesRoutes.routes)

    return router
  }
}
