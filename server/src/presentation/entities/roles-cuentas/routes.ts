import { Router } from 'express'
import { RolesCuentasController } from '@/presentation/entities/roles-cuentas/controller'

export class RolesCuentasRoutes {
  static get routes() {
    const router = Router()
    const rolesCuentasController = new RolesCuentasController()

    router.get('/', rolesCuentasController.getAll)

    return router
  }
}
