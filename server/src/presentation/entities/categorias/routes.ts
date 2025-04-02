import { Router } from 'express'
import { CategoriasController } from '@/presentation/entities/categorias/controller'

export class CategoriasRoutes {
  static get routes() {
    const router = Router()
    const categoriasController = new CategoriasController()

    router.post('/', categoriasController.create)
    router.get('/:id', categoriasController.getById)
    router.get('/', categoriasController.getAll)
    router.patch('/:id', categoriasController.update)
    router.delete('/id', categoriasController.delete)
    return router
  }
}
