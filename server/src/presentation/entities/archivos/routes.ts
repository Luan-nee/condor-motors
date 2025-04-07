import { Router } from 'express'
import { ArchivosController } from '@/presentation/entities/archivos/controller'
import { FilesMiddleware } from '@/presentation/middlewares/files.middleware'
import { AccessControlMiddleware } from '@/presentation/middlewares/access-control.middleware'
import { permissionCodes } from '@/consts'
import { JwtAdapter } from '@/config/jwt'
import { envs } from '@/config/envs'

export class ArchivosRoutes {
  private static readonly fileFieldName = 'app_file'

  static get routes() {
    const router = Router()

    const archivosController = new ArchivosController(
      JwtAdapter,
      envs.PRIVATE_STORAGE_PATH
    )

    router.post(
      '/upload',
      [
        AccessControlMiddleware.requests([permissionCodes.archivos.createAny]),
        FilesMiddleware.apkDesktopApp.single(ArchivosRoutes.fileFieldName)
      ],
      archivosController.uploadFile
    )

    router.post(
      '/share',
      [AccessControlMiddleware.requests([permissionCodes.archivos.createAny])],
      archivosController.share
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

    router.get(
      '/download/:filename',
      [
        AccessControlMiddleware.requests([
          permissionCodes.archivos.getAny,
          permissionCodes.archivos.getVisible
        ])
      ],
      archivosController.download
    )

    router.delete(
      '/:id',
      [AccessControlMiddleware.requests([permissionCodes.archivos.deleteAny])],
      archivosController.delete
    )

    return router
  }
}
