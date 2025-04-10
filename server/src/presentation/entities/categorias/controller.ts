import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateCategoriaDto } from '@/domain/dtos/entities/categorias/create-categoria.dto'
import { CreateCategoria } from '@/domain/use-cases/entities/categorias/create-categorias.use-case'
import { GetCategorias } from '@/domain/use-cases/entities/categorias/get-categorias.use-case'
import { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import type { Request, Response } from 'express'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { GetCategoriaById } from '@/domain/use-cases/entities/categorias/get-categoria-by-id.use-case'
import { UpdateCategoriaDto } from '@/domain/dtos/entities/categorias/update-categoria.dto'
import { UpdateCategoria } from '@/domain/use-cases/entities/categorias/update-categorias.use-case'
import { DeleteCategoria } from '@/domain/use-cases/entities/categorias/delete.use-case'

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

    const [error, queriesDto] = QueriesDto.create(req.query)

    if (error !== undefined || queriesDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const getCategorias = new GetCategorias()

    getCategorias
      .execute(queriesDto)
      .then((categorias) => {
        CustomResponse.success({
          res,
          data: categorias.results,
          metadata: categorias.metadata
        })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  getById = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [error, numericIdDto] = NumericIdDto.create(req.params)

    if (error !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: 'id Invalido' })
      return
    }

    const { authPayload } = req
    const getCategoriaById = new GetCategoriaById(authPayload)
    getCategoriaById
      .execute(numericIdDto)
      .then((categoria) => {
        CustomResponse.success({ res, data: categoria })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  update = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [paramErrors, numericIdDto] = NumericIdDto.create(req.params)

    if (paramErrors !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: 'El id es invalido' })
      return
    }

    const [updateCategoriaValidationError, updateCategoriaDto] =
      UpdateCategoriaDto.create(req.body)

    if (
      updateCategoriaValidationError !== undefined ||
      updateCategoriaDto === undefined
    ) {
      CustomResponse.badRequest({ res, error: updateCategoriaValidationError })
      return
    }
    const { authPayload } = req
    const updateCategoria = new UpdateCategoria(authPayload)

    updateCategoria
      .execute(updateCategoriaDto, numericIdDto)
      .then((categoria) => {
        const message = `La categoria con id ${categoria.id} ha sido actualizada`
        CustomResponse.success({ res, message, data: categoria })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  delete = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [error, numericIdDto] = NumericIdDto.create(req.params)

    if (error !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: 'Id invalido' })
      return
    }

    const deleteCategoria = new DeleteCategoria()

    deleteCategoria
      .execute(numericIdDto)
      .then((categoria) => {
        const message = ` Categoria con el ID : ${categoria.id} eliminado`

        CustomResponse.success({ res, message, data: categoria })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
