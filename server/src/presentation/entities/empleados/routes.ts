import { permissionCodes } from '@/consts'
import { AccessControlMiddleware } from '@/presentation/middlewares/access-control.middleware'
import { EmpleadosController } from '@presentation/entities/empleados/controller'
import { Router } from 'express'

export class EmpleadosRoutes {
  static get routes() {
    const router = Router()

    const empleadosController = new EmpleadosController()

    router.post(
      '/',
      [AccessControlMiddleware.requests([permissionCodes.empleados.createAny])],
      empleadosController.create
    )

    router.get('/:id', empleadosController.getById)

    router.get('/', empleadosController.getAll)

    router.patch('/:id', empleadosController.update)

    // router.delete('/:id', empleadosController.delete)

    return router
  }
}
