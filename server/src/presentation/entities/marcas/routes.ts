import { Router } from 'express'
import { MarcasController } from './controller'

/**
 * Rutas para el manejo de marcas
 * 
 * GET /marcas - Obtener todas las marcas (paginado)
 *   Query params:
 *     - page: número de página (default: 1)
 *     - pageSize: tamaño de página (default: 10)
 * GET /marcas/:id - Obtener una marca por ID
 * POST /marcas - Crear una nueva marca
 * PUT /marcas/:id - Actualizar una marca existente
 * DELETE /marcas/:id - Eliminar una marca
 */
export class MarcasRoutes {
  static get routes() {
    const router = Router()
    const controller = new MarcasController()

    router.get('/', controller.getAll)

    router.get('/:id', controller.getById)
    
    router.post('/', controller.create)
    
    router.put('/:id', controller.update)
    
    router.delete('/:id', controller.delete)
    return router
  }
}
