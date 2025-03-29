import { Router } from 'express'
import { ServicioFacturacion } from '@/config/facturacion'
import { FacturacionController } from '@/presentation/entities/solo-sucursal/facturacion/controller'

export class FacturacionRoutes {
  static get routes() {
    const router = Router()

    const facturacionController = new FacturacionController(ServicioFacturacion)

    router.post('/declarar', facturacionController.declare)

    router.post('/consultar', facturacionController.sync)

    router.post('/anular', facturacionController.anular)

    return router
  }
}
