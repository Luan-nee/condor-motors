import { Router } from 'express'
import { EstadisticasController } from './controller'

export class EstadisticaRouter {
  static get routes() {
    const router = Router()
    const estadisticasController = new EstadisticasController()

    router.get('/ventas', estadisticasController.getReporteVentas)
    router.get('/productos', estadisticasController.getStockBajoLiquidacion)
    return router
  }
}
