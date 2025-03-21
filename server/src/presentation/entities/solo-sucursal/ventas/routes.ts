import { Router } from 'express'
import { VentasController } from '@/presentation/entities/solo-sucursal/ventas/controller'
import { envs } from '@/config/envs'

export class VentasRoutes {
  static get routes() {
    const router = Router()

    const { TOKEN_EMPRESA_FACTPRO: tokenFacturacion } = envs
    const ventasController = new VentasController(tokenFacturacion)

    router.post('/', ventasController.create)

    router.get('/:id', ventasController.getById)

    router.get('/', ventasController.getAll)

    router.patch('/:id', ventasController.update)

    // router.delete('/:id', ventasController.delete)

    return router
  }
}
