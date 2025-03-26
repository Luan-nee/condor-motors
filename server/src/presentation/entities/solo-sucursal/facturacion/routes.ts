import { Router } from 'express'
import { ServicioFacturacion } from '@/config/facturacion'
import { FacturacionController } from '@/presentation/entities/solo-sucursal/facturacion/controller'

export class FacturacionRoutes {
  static get routes() {
    const router = Router()

    const ventasController = new FacturacionController(ServicioFacturacion)

    router.post('/declarar', ventasController.declare)
    router.post('/consultar', ventasController.sync)

    return router
  }
}
