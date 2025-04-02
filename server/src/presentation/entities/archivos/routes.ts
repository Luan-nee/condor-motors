import { Router } from 'express'
import { ArchivosController } from '@/presentation/entities/archivos/controller'
import { FilesMiddleware } from '@/presentation/middlewares/files.middleware'
import { AccessControlMiddleware } from '@/presentation/middlewares/access-control.middleware'
import { permissionCodes } from '@/consts'

export class ArchivosRoutes {
  private static readonly fileFieldName = 'app_file'

  static get routes() {
    const router = Router()

    const archivosController = new ArchivosController()

    router.post(
      '/apk',
      [
        AccessControlMiddleware.requests([permissionCodes.archivos.createAny]),
        FilesMiddleware.apk.single(ArchivosRoutes.fileFieldName)
      ],
      archivosController.uploadApk
    )

    router.post(
      '/desktop-app',
      [
        AccessControlMiddleware.requests([permissionCodes.archivos.createAny])
        // FilesMiddleware.desktopApp.single(ArchivosRoutes.fileFieldName)
      ],
      archivosController.uploadDesktopApp
    )

    router.get(
      '/',
      [
        AccessControlMiddleware.requests([
          permissionCodes.archivos.getAny,
          permissionCodes.archivos.getVisible
        ])
      ],
      archivosController.getAll
    )

    router.delete(
      '/:id',
      [AccessControlMiddleware.requests([permissionCodes.archivos.deleteAny])],
      archivosController.delete
    )

    return router
  }
}
