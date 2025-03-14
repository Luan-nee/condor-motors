import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateMarcasDto } from '@/domain/dtos/entities/marcas/create-marcas.dto'
import { UpdateMarcasDto } from '@/domain/dtos/entities/marcas/update-marcas.dto'
import { CreateMarcas } from '@/domain/use-cases/entities/marcas/create-marcas.use-case'
import { UpdateMarcas } from '@/domain/use-cases/entities/marcas/update-marcas.use-case'
import { DeleteMarcas } from '@/domain/use-cases/entities/marcas/delete-marcas.use-case'
import { GetAllMarcas } from '@/domain/use-cases/entities/marcas/get-all-marcas.use-case'
import { GetMarcaById } from '@/domain/use-cases/entities/marcas/get-marca-by-id.use-case'
import type { Request, Response } from 'express'

interface MarcaResponse {
  id: number
  nombre: string
  descripcion?: string
}

export class MarcasController {
  getAll = async (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res, error: 'Invalid access token' })
      return
    }

    try {
      // Obtener parámetros de paginación de la query con validación de tipo
      let page = 1
      let pageSize = 10

      // Validar y convertir page
      if (req.query.page !== undefined) {
        const pageParam = Number(req.query.page)
        if (!Number.isNaN(pageParam)) {
          page = pageParam
        }
      }

      // Validar y convertir pageSize
      if (req.query.pageSize !== undefined) {
        const pageSizeParam = Number(req.query.pageSize)
        if (!Number.isNaN(pageSizeParam)) {
          pageSize = pageSizeParam
        }
      }

      // Validar que los parámetros sean positivos
      if (page < 1 || pageSize < 1) {
        CustomResponse.badRequest({
          res,
          error: 'Los parámetros de paginación deben ser números positivos'
        })
        return
      }

      // Usar el caso de uso para obtener las marcas paginadas
      const getAllMarcas = new GetAllMarcas()
      const result = await getAllMarcas.execute(page, pageSize)

      CustomResponse.success({ res, data: result })
    } catch (error) {
      handleError(error, res)
    }
  }

  getById = async (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res, error: 'Invalid access token' })
      return
    }

    const id = parseInt(req.params.id, 10)
    if (Number.isNaN(id) || id <= 0) {
      CustomResponse.badRequest({ res, error: 'ID inválido' })
      return
    }

    try {
      // Usar el caso de uso para obtener la marca por ID
      const getMarcaById = new GetMarcaById()
      const marca = await getMarcaById.execute(id)

      if (marca === null) {
        res.status(404).json({
          ok: false,
          error: 'Marca no encontrada'
        })
        return
      }

      CustomResponse.success({ res, data: marca })
    } catch (error) {
      handleError(error, res)
    }
  }

  create = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res, error: 'Invalid access token' })
      return
    }

    const [error, createMarcasDto] = CreateMarcasDto.create(req.body)
    if (error !== undefined || createMarcasDto === undefined) {
      CustomResponse.badRequest({ res, error: error ?? 'Datos inválidos' })
      return
    }

    const createMarcas = new CreateMarcas()

    createMarcas
      .execute(createMarcasDto)
      .then((marcas: MarcaResponse) => {
        CustomResponse.success({ res, data: marcas })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  update = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res, error: 'Invalid access token' })
      return
    }

    const id = parseInt(req.params.id, 10)
    const [error, updateMarcasDto] = UpdateMarcasDto.create({ ...req.body, id })

    if (error !== undefined || updateMarcasDto === undefined) {
      CustomResponse.badRequest({ res, error: error ?? 'Datos inválidos' })
      return
    }

    const updateMarcas = new UpdateMarcas()

    updateMarcas
      .execute(updateMarcasDto)
      .then((marcas: MarcaResponse | null) => {
        if (marcas === null) {
          res.status(404).json({
            ok: false,
            error: 'Marca no encontrada'
          })
          return
        }
        CustomResponse.success({ res, data: marcas })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  delete = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res, error: 'Invalid access token' })
      return
    }

    const id = parseInt(req.params.id, 10)
    if (Number.isNaN(id) || id <= 0) {
      CustomResponse.badRequest({ res, error: 'ID inválido' })
      return
    }

    const deleteMarcas = new DeleteMarcas()

    deleteMarcas
      .execute(id)
      .then((marcas: MarcaResponse | null) => {
        if (marcas === null) {
          res.status(404).json({
            ok: false,
            error: 'Marca no encontrada'
          })
          return
        }
        CustomResponse.success({
          res,
          data: { message: 'Marca eliminada correctamente' }
        })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
