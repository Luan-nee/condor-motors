import { Router } from 'express'
import { TransferenciasInventarioController } from './controller'

export class TransferenciasInventarioRouter {
  static get routes() {
    const router = Router()
    const transferenciaInventarioController =
      new TransferenciasInventarioController()

    router.get('/', transferenciaInventarioController.getAll)

    return router
  }
}
