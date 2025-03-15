import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateCategoriaDto } from '@/domain/dtos/entities/categorias/create-categoria.dto'
import { CreateCategoria } from '@/domain/use-cases/entities/categorias/create-categorias.use-case'
import { GetCategorias } from '@/domain/use-cases/entities/categorias/get-categorias.use-case'
import { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import type { Request, Response } from 'express'

export class CategoriasController {
  create = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }
    const [error, createCategoriaDto] = CreateCategoriaDto.create(req.body)

    if (error !== undefined || createCategoriaDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload } = req

    const createCategoria = new CreateCategoria(authPayload)

    createCategoria
      .execute(createCategoriaDto)
      .then((categoria) => {
        CustomResponse.success({ res, data: categoria })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  getAll = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const { authPayload } = req
    const [error, queriesDto] = QueriesDto.create(req.query)

    if (error !== undefined || queriesDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const getCategorias = new GetCategorias(authPayload)

    getCategorias
      .execute(queriesDto)
      .then((categorias) => {
        CustomResponse.success({ res, data: categorias })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
