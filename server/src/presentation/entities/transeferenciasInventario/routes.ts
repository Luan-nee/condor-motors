import { Router } from 'express'
import { TransferenciasInventarioController } from './controller'

export class TransferenciasInventarioRoutes {
  static get routes() {
    const router = Router()
    const transferenciaInventarioController =
      new TransferenciasInventarioController()

    router.post('/', transferenciaInventarioController.create)
    router.post('/enviar', transferenciaInventarioController.enviar)
    router.post('/recibir', transferenciaInventarioController.recibir)

    router.get('/:id', transferenciaInventarioController.getById)

    router.get('/', transferenciaInventarioController.getAll)

    router.patch('/:id', transferenciaInventarioController.update)

    router.delete('/:id', transferenciaInventarioController.delete)

    return router
  }
}
