import { Router } from 'express'
import { ArchivosController } from '@/presentation/entities/archivos/controller'
import { FilesMiddleware } from '@/presentation/middlewares/files.middleware'
import { AccessControlMiddleware } from '@/presentation/middlewares/access-control.middleware'
import { permissionCodes } from '@/consts'

export class ArchivosRoutes {
  private static readonly fileFieldName = 'app_file'

  static get routes() {
    const router = Router()

    const sucursalesController = new ArchivosController()

    router.post(
      '/apk',
      [
        AccessControlMiddleware.requests([permissionCodes.archivos.createAny]),
        FilesMiddleware.apk.single(ArchivosRoutes.fileFieldName)
      ],
      sucursalesController.uploadApk
    )

    router.post(
      '/desktop-app',
      [
        AccessControlMiddleware.requests([permissionCodes.archivos.createAny])
        // FilesMiddleware.desktopApp.single(ArchivosRoutes.fileFieldName)
      ],
      sucursalesController.uploadDesktopApp
    )

    router.get('/', sucursalesController.getAll)

    router.delete('/:id', sucursalesController.delete)

    return router
  }
}
