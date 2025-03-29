import { Router } from 'express'
import { VentasController } from '@/presentation/entities/solo-sucursal/ventas/controller'

export class VentasRoutes {
  static get routes() {
    const router = Router()

    const ventasController = new VentasController()

    router.post('/', ventasController.create)

    router.post('/:id/cancelar', ventasController.cancelar)

    router.get('/informacion', ventasController.getInformacion)

    router.get('/:id', ventasController.getById)

    router.get('/', ventasController.getAll)

    router.patch('/:id', ventasController.update)

    return router
  }
}
