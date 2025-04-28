import { envs } from '@/config/envs'
import { permissionCodes } from '@/consts'
import { createDirIfNotExists } from '@/core/lib/filesystem'
import { AccessControlMiddleware } from '@/presentation/middlewares/access-control.middleware'
import { FilesMiddleware } from '@/presentation/middlewares/files.middleware'
import { EmpleadosController } from '@presentation/entities/empleados/controller'
import { Router } from 'express'

export class EmpleadosRoutes {
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

    const empleadosController = new EmpleadosController(
      envs.PUBLIC_STORAGE_PATH,
      this.filesDirectory
    )

    const router = Router()

    router.post(
      '/',
      [
        AccessControlMiddleware.requests([permissionCodes.empleados.createAny]),
        FilesMiddleware.image.single(EmpleadosRoutes.fileFieldName)
      ],
      empleadosController.create
    )

    router.get('/:id', empleadosController.getById)

    router.get('/', empleadosController.getAll)

    router.patch(
      '/:id',
      [
        AccessControlMiddleware.requests([permissionCodes.empleados.updateAny]),
        FilesMiddleware.image.single(EmpleadosRoutes.fileFieldName)
      ],
      empleadosController.update
    )

    // router.delete('/:id', empleadosController.delete)

    return router
  }
}
