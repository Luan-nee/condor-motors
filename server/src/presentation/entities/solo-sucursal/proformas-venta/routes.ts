import { Router } from 'express'
import { ProformasVentaController } from '@/presentation/entities/solo-sucursal/proformas-venta/controller'

export class ProformasVentaRoutes {
  static get routes() {
    const router = Router()

    const proformasVentaController = new ProformasVentaController()

    router.post('/', proformasVentaController.create)

    // router.get('/:id', proformasVentaController.getById)

    router.get('/', proformasVentaController.getAll)

    router.patch('/:id', proformasVentaController.update)

    router.delete('/:id', proformasVentaController.delete)

    return router
  }
}
