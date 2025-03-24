import { Router } from 'express'
import { ReservasProductosController } from './controller'

export class ReservasProductoRoutes {
  static get routes() {
    const router = Router()

    const ReservasProducto = new ReservasProductosController()

    router.post('/', ReservasProducto.create)

    return router
  }
}
