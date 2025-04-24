import { envs } from '@/config/envs'
import { permissionCodes } from '@/consts'
import { AccessControlMiddleware } from '@/presentation/middlewares/access-control.middleware'
import { FilesMiddleware } from '@/presentation/middlewares/files.middleware'
import { EmpleadosController } from '@presentation/entities/empleados/controller'
import { Router } from 'express'

export class EmpleadosRoutes {
  private static readonly fileFieldName = 'foto'

  static get routes() {
    const router = Router()

    const empleadosController = new EmpleadosController(
      envs.PUBLIC_STORAGE_PATH
    )

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

    router.patch('/:id', empleadosController.update)

    // router.delete('/:id', empleadosController.delete)

    return router
  }
}
