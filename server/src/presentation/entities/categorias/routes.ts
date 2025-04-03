import { Router } from 'express'
import { CategoriasController } from '@/presentation/entities/categorias/controller'
import { AccessControlMiddleware } from '@/presentation/middlewares/access-control.middleware'
import { permissionCodes } from '@/consts'

export class CategoriasRoutes {
  static get routes() {
    const router = Router()
    const categoriasController = new CategoriasController()

    router.post(
      '/',
      [
        AccessControlMiddleware.requests([permissionCodes.categorias.createAny])
      ],
      categoriasController.create
    )
    router.get('/:id', categoriasController.getById)
    router.get('/', categoriasController.getAll)
    router.patch(
      '/:id',
      [
        AccessControlMiddleware.requests([permissionCodes.categorias.updateAny])
      ],
      categoriasController.update
    )
    router.delete(
      '/:id',
      [
        AccessControlMiddleware.requests([permissionCodes.categorias.deleteAny])
      ],
      categoriasController.delete
    )

    return router
  }
}
