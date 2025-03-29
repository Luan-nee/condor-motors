import { Router } from 'express'
import { ClientesController } from './controller'
import { ServicioConsulta } from '@/config/consultas'

export class ClientesRoutes {
  static get routes() {
    const router = Router()

    const clientesController = new ClientesController(ServicioConsulta)

    router.post('/', clientesController.create)

    router.get('/:id', clientesController.getById)

    router.get('/doc/:doc', clientesController.getByDoc)

    router.get('/', clientesController.getAll)

    router.patch('/:id', clientesController.update)

    return router
  }
}
