import { EmpleadosController } from '@presentation/entities/empleados/controller'
import { Router } from 'express'

export class EmpleadosRoutes {
  static get routes() {
    const router = Router()

    const empleadosController = new EmpleadosController()

    router.post('/', empleadosController.create)

    router.get('/:id', empleadosController.getById)

    router.get('/', empleadosController.getAll)

    router.patch('/:id', empleadosController.update)

    // router.put('/:id/activar', empleadosController.activar)
    // router.put('/:id/desactivar', empleadosController.desactivar)

    // router.delete('/:id', empleadosController.delete)

    return router
  }
}
