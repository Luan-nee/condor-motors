import { Router } from 'express'
import { EstadisticasController } from './controller'

export class EstadisticaRouter {
  static get routes() {
    const router = Router()
    const estadisticasController = new EstadisticasController()

    router.get('/', estadisticasController.getReporteVentas)
    router.get(
      '/stockBajoLiquidacion',
      estadisticasController.getStockBajoLiquidacion
    )
    return router
  }
}
