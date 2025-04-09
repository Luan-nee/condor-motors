import { Router } from 'express'
import { TransferenciasInventarioController } from './controller'

export class TransferenciasInventarioRoutes {
  static get routes() {
    const router = Router()
    const transferenciaInventarioController =
      new TransferenciasInventarioController()

    router.post('/', transferenciaInventarioController.create)

    router.post('/:id/enviar', transferenciaInventarioController.enviar)

    router.post('/:id/recibir', transferenciaInventarioController.recibir)

    router.post('/:id/cancelar', transferenciaInventarioController.cancelar)

    router.post('/:id/comparar', transferenciaInventarioController.comparar)

    router.get('/:id', transferenciaInventarioController.getById)

    router.get('/', transferenciaInventarioController.getAll)

    router.post('/:id/items', transferenciaInventarioController.addItems)

    router.patch(
      '/:id/items/:secondId',
      transferenciaInventarioController.updateItems
    )

    router.delete(
      '/:id/items/:secondId',
      transferenciaInventarioController.removeItems
    )

    router.delete('/:id', transferenciaInventarioController.delete)

    return router
  }
}
