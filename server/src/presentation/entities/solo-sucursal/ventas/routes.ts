import { Router } from 'express'
import { VentasController } from '@/presentation/entities/solo-sucursal/ventas/controller'

export class VentasRoutes {
  static get routes() {
    const router = Router()

    const ventasController = new VentasController()

    router.post('/', ventasController.create)

    router.get('/:id', ventasController.getById)

    router.get('/', ventasController.getAll)

    router.patch('/:id', ventasController.update)

    router.get('/informacion', ventasController.getInformacion)
    // router.delete('/:id', ventasController.delete)

    return router
  }
}
