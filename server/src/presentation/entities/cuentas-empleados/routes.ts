import { Router } from 'express'
import { CuentasEmpleadosController } from '@/presentation/entities/cuentas-empleados/controller'

export class CuentasEmpleadosRoutes {
  static get routes() {
    const router = Router()

    const cuentasEmpleadosController = new CuentasEmpleadosController()

    // router.post('/', cuentasEmpleadosController.create)

    router.get('/:id', cuentasEmpleadosController.getById)

    router.get('/', cuentasEmpleadosController.getAll)

    router.patch('/:id', cuentasEmpleadosController.update)

    router.delete('/:id', cuentasEmpleadosController.delete)

    return router
  }
}
