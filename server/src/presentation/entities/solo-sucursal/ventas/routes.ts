import { Router } from 'express'
import { VentasController } from '@/presentation/entities/solo-sucursal/ventas/controller'
import { ServicioFacturacion } from '@/config/facturacion'

export class VentasRoutes {
  static get routes() {
    const router = Router()

    const ventasController = new VentasController(ServicioFacturacion)

    router.post('/', ventasController.create)

    router.post('/:id/declarar', ventasController.declarar)

    router.get('/:id', ventasController.getById)

    router.get('/', ventasController.getAll)

    router.patch('/:id', ventasController.update)

    // router.delete('/:id', ventasController.delete)

    return router
  }
}
