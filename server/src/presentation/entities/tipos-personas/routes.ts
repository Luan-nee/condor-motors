import { Router } from 'express'
import { TiposPersonasController } from '@/presentation/entities/tipos-personas/controller'

export class TiposPersonasRoutes {
  static get routes() {
    const router = Router()
    const tiposPersonasController = new TiposPersonasController()

    router.get('/', tiposPersonasController.getAll)

    return router
  }
}
