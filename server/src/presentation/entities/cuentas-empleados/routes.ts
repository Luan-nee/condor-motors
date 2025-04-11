import { Router } from 'express'
import { CuentasEmpleadosController } from '@/presentation/entities/cuentas-empleados/controller'
import { JwtAdapter } from '@/config/jwt'
import { BcryptAdapter } from '@/config/bcrypt'
import { AccessControlMiddleware } from '@/presentation/middlewares/access-control.middleware'
import { permissionCodes } from '@/consts'

export class CuentasEmpleadosRoutes {
  static get routes() {
    const router = Router()

    const cuentasEmpleadosController = new CuentasEmpleadosController(
      JwtAdapter,
      BcryptAdapter
    )

    router.post(
      '/',
      AccessControlMiddleware.requests([
        permissionCodes.cuentasEmpleados.createAny
      ]),
      cuentasEmpleadosController.create
    )

    router.get('/:id', cuentasEmpleadosController.getById)

    router.get('/', cuentasEmpleadosController.getAll)

    router.patch('/:id', cuentasEmpleadosController.update)

    router.delete('/:id', cuentasEmpleadosController.delete)

    return router
  }
}
