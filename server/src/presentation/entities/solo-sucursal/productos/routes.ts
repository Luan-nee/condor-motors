import { Router } from 'express'
import { ProductosController } from '@/presentation/entities/solo-sucursal/productos/controller'
import { envs } from '@/config/envs'
import { AccessControlMiddleware } from '@/presentation/middlewares/access-control.middleware'
import { permissionCodes } from '@/consts'
import { FilesMiddleware } from '@/presentation/middlewares/files.middleware'

export class ProductosRoutes {
  private static readonly fileFieldName = 'foto'

  static get routes() {
    const router = Router()

    const productosController = new ProductosController(
      envs.PUBLIC_STORAGE_PATH,
      '/static/img'
    )

    router.post(
      '/',
      [
        AccessControlMiddleware.requests([
          permissionCodes.productos.createAny,
          permissionCodes.productos.createRelated
        ]),
        FilesMiddleware.image.single(ProductosRoutes.fileFieldName)
      ],
      productosController.create
    )

    router.post('/:id', productosController.add)

    router.get('/:id', productosController.getById)

    router.get('/', productosController.getAll)

    router.patch(
      '/:id',
      [
        AccessControlMiddleware.requests([
          permissionCodes.productos.updateAny,
          permissionCodes.productos.updateRelated
        ]),
        FilesMiddleware.image.single(ProductosRoutes.fileFieldName)
      ],
      productosController.update
    )

    // router.delete('/:id', productosController.delete)

    return router
  }
}
