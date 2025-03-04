import { EmpleadosController } from '@presentation/entities/empleados/controller'
import { Router } from 'express'

export class EmpleadosRoutes {
  static get routes() {
    const router = Router()

    const empleadosController = new EmpleadosController()

    router.post('/', empleadosController.create)
    return router
  }
}
