import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { AddProductoDto } from '@/domain/dtos/entities/productos/add-producto.dto'
import { CreateProductoDto } from '@/domain/dtos/entities/productos/create-producto.dto'
import { QueriesProductoDto } from '@/domain/dtos/entities/productos/queries-producto.dto'
import { UpdateProductoDto } from '@/domain/dtos/entities/productos/update-producto.dto'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { AddProducto } from '@/domain/use-cases/entities/productos/add-producto.use-case'
import { CreateProducto } from '@/domain/use-cases/entities/productos/create-producto.use-case'
import { GetProductoById } from '@/domain/use-cases/entities/productos/get-producto-by-id.use-case'
import { GetProductos } from '@/domain/use-cases/entities/productos/get-productos.use-case'
import { UpdateProducto } from '@/domain/use-cases/entities/productos/update-producto.use-case'
import type { Request, Response } from 'express'

export class ProductosController {
  constructor(
    private readonly publicStoragePath: string,
    private readonly photosDirectory?: string
  ) {}

  create = (req: Request, res: Response) => {
    if (req.authPayload === undefined || req.permissions == null) {
      CustomResponse.unauthorized({ res })
      return
    }

    if (req.sucursalId === undefined) {
      CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
      return
    }

    const [error, createProductoDto] = CreateProductoDto.create(req.body)

    if (error !== undefined || createProductoDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { sucursalId, file, permissions } = req

    const createProducto = new CreateProducto(
      permissions,
      this.publicStoragePath,
      this.photosDirectory
    )

    createProducto
      .execute(createProductoDto, sucursalId, file)
      .then((producto) => {
        CustomResponse.success({ res, data: producto })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  add = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    if (req.sucursalId === undefined) {
      CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
      return
    }

    const [paramErrors, numericIdDto] = NumericIdDto.create(req.params)
    if (paramErrors !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: paramErrors })
      return
    }

    const [error, addProductoDto] = AddProductoDto.create(req.body)

    if (error !== undefined || addProductoDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload, sucursalId } = req

    const addProducto = new AddProducto(authPayload)

    addProducto
      .execute(numericIdDto, addProductoDto, sucursalId)
      .then((detalleProducto) => {
        CustomResponse.success({ res, data: detalleProducto })
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

    if (req.sucursalId === undefined) {
      CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
      return
    }

    const [error, numericIdDto] = NumericIdDto.create(req.params)
    if (error !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload, sucursalId } = req

    const getProdcutoById = new GetProductoById(authPayload)

    getProdcutoById
      .execute(numericIdDto, sucursalId)
      .then((producto) => {
        CustomResponse.success({ res, data: producto })
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

    if (req.sucursalId === undefined) {
      CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
      return
    }

    const [error, queriesProductoDto] = QueriesProductoDto.create(req.query)
    if (error !== undefined || queriesProductoDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload, sucursalId } = req

    const getProductos = new GetProductos(authPayload)

    getProductos
      .execute(queriesProductoDto, sucursalId)
      .then((productos) => {
        CustomResponse.success({
          res,
          data: productos.results,
          pagination: productos.pagination,
          metadata: productos.metadata
        })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  update = (req: Request, res: Response) => {
    if (req.authPayload === undefined || req.permissions === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    if (req.sucursalId === undefined) {
      CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
      return
    }

    const [paramErrors, numericIdDto] = NumericIdDto.create(req.params)
    if (paramErrors !== undefined || numericIdDto === undefined) {
      CustomResponse.badRequest({ res, error: paramErrors })
      return
    }

    const { sucursalId, permissions, file } = req

    const [error, updateProductoDto] = UpdateProductoDto.create(
      req.body,
      file?.size
    )
    if (error !== undefined || updateProductoDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const updateProducto = new UpdateProducto(
      permissions,
      this.publicStoragePath,
      this.photosDirectory
    )

    updateProducto
      .execute(numericIdDto, updateProductoDto, sucursalId, file)
      .then((producto) => {
        const message = `El producto con el id ${producto.id} ha sido actualizado`

        CustomResponse.success({
          res,
          message,
          data: producto
        })
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

    CustomResponse.notImplemented({ res })
  }
}
