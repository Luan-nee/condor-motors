import { Router } from 'express'
import { InventariosController } from '@/presentation/entities/solo-sucursal/inventarios/controller'

export class InventariosRoutes {
  static get routes() {
    const router = Router()

    const inventariosController = new InventariosController()

    router.post('/entradas', inventariosController.entradas)

    // router.use('/salidas', this.salidas())

    return router
  }
}
