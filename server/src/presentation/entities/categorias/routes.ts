import { Router } from 'express'
import { CategoriasController } from '@/presentation/entities/categorias/controller'

export class CategoriasRoutes {
  static get routes() {
    const router = Router()
    const categoriasController = new CategoriasController()

    router.get('/', categoriasController.getAll)

    router.post('/', categoriasController.create)

    return router
  }
}
