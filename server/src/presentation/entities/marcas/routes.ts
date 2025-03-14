import { Router } from 'express'
import { MarcasController } from './controller'

/**
 * Rutas para el manejo de marcas
 * 
 * GET /marcas - Obtener todas las marcas (paginado)
 *   Query params:
 *     - page: número de página (default: 1, debe ser un número positivo)
 *     - pageSize: tamaño de página (default: 10, debe ser un número positivo)
 * GET /marcas/:id - Obtener una marca por ID
 * POST /marcas - Crear una nueva marca
 * PUT /marcas/:id - Actualizar una marca existente
 * DELETE /marcas/:id - Eliminar una marca
 */
export class MarcasRoutes {
  static get routes() {
    const router = Router()
    const controller = new MarcasController()

    // Ruta para obtener todas las marcas (con paginación)
    router.get('/', controller.getAll)

    // Ruta para obtener una marca por ID
    router.get('/:id', controller.getById)
    
    // Ruta para crear una nueva marca
    router.post('/', controller.create)
    
    // Ruta para actualizar una marca existente
    router.put('/:id', controller.update)
    
    // Ruta para eliminar una marca
    router.delete('/:id', controller.delete)
    
    return router
  }
}
