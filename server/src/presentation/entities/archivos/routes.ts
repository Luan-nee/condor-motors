import { Router } from 'express'
import { ArchivosController } from '@/presentation/entities/archivos/controller'

export class ArchivosRoutes {
  static get routes() {
    const router = Router()

    const sucursalesController = new ArchivosController()

    router.post('/', sucursalesController.create)

    router.get('/', sucursalesController.getAll)

    router.delete('/:id', sucursalesController.delete)

    return router
  }
}
