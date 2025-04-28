import { Router } from 'express'
import { ProductosController } from '@/presentation/entities/solo-sucursal/productos/controller'
import { envs } from '@/config/envs'
import { AccessControlMiddleware } from '@/presentation/middlewares/access-control.middleware'
import { permissionCodes } from '@/consts'
import { FilesMiddleware } from '@/presentation/middlewares/files.middleware'
import { createDirIfNotExists } from '@/core/lib/filesystem'

export class ProductosRoutes {
  private static readonly fileFieldName = 'foto'
  private static readonly filesDirectory = '/static/img'

  static get routes() {
    createDirIfNotExists(envs.PUBLIC_STORAGE_PATH, this.filesDirectory)
      .then()
      .catch((error: unknown) => {
        if (error instanceof Error) {
          throw error
        }
      })

    const productosController = new ProductosController(
      envs.PUBLIC_STORAGE_PATH,
      this.filesDirectory
    )

    const router = Router()

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
