import { Router } from 'express'
import { MarcasController } from './controller'
import { AccessControlMiddleware } from '@/presentation/middlewares/access-control.middleware'
import { permissionCodes } from '@/consts'

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

    // Ruta para crear una nueva marca
    router.post(
      '/',
      [AccessControlMiddleware.requests([permissionCodes.marcas.createAny])],
      controller.create
    )

    // Ruta para obtener todas las marcas (con paginación)
    router.get('/', controller.getAll)

    // Ruta para obtener una marca por ID
    router.get('/:id', controller.getById)

    // Ruta para actualizar una marca existente
    router.patch(
      '/:id',
      [AccessControlMiddleware.requests([permissionCodes.marcas.updateAny])],
      controller.update
    )

    // Ruta para eliminar una marca
    router.delete(
      '/:id',
      [AccessControlMiddleware.requests([permissionCodes.marcas.deleteAny])],
      controller.delete
    )

    return router
  }
}
