import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { QueriesProductoDto } from '@/domain/dtos/entities/productos/queries-producto.dto'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { GetProductosNombre } from '@/domain/use-cases/entities/productos/get-all-productos-nombre-use-case'
import { GetByIdData } from '@/domain/use-cases/entities/productos/get-bt-id-dates-use-case'
import { GetProductosReporte } from '@/domain/use-cases/entities/reporte/get-all-productosReporte.use-case'
import type { Request, Response } from 'express'

export class ProductosController {
  detalles = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.invalidAccessToken({ res })
    }

    const [error, numericIdDto] = NumericIdDto.create(req.params)
    if (error != null || numericIdDto == null) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const getProdcutoById = new GetByIdData()

    getProdcutoById
      .execute(numericIdDto.id)
      .then((data) => {
        CustomResponse.success({
          res,
          data
        })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  getAll = (req: Request, res: Response) => {
    const [error, queriesDto] = QueriesProductoDto.create(req.query)

    if (error !== undefined || queriesDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const getProductos = new GetProductosNombre()

    getProductos
      .execute(queriesDto)
      .then((productos) => {
        CustomResponse.success({ res, data: productos })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  getReporteProducto = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.invalidAccessToken({ res })
      return
    }
    const getresporte = new GetProductosReporte()

    getresporte
      .execute()
      .then((reporte) => {
        CustomResponse.success({ res, data: reporte })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
