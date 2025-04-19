import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { GetReporteVentas } from '@/domain/use-cases/entities/estadisticas/get-estadisticas.use-case'
import { GetStockBajoLiquidacion } from '@/domain/use-cases/entities/estadisticas/get-stockbajo.use-case'
import { GetUltimasVentas } from '@/domain/use-cases/entities/estadisticas/get-ultimas-ventas.use-case'
import type { Request, Response } from 'express'

export class EstadisticasController {
  getReporteVentas = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.invalidAccessToken({ res })
      return
    }

    const [error, queriesDto] = QueriesDto.create(req.query)
    if (error !== undefined || queriesDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const getReporteVentas = new GetReporteVentas()

    getReporteVentas
      .execute()
      .then((reporte) => {
        CustomResponse.success({ res, data: reporte })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  getUltimasVentas = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.invalidAccessToken({ res })
      return
    }

    const [error, queriesDto] = QueriesDto.create(req.query)
    if (error !== undefined || queriesDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const getUltimasVentas = new GetUltimasVentas()

    getUltimasVentas
      .execute()
      .then((ultimasVentas) => {
        CustomResponse.success({ res, data: ultimasVentas })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  getStockBajoLiquidacion = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
    }
    const getReporteStockLiquidacion = new GetStockBajoLiquidacion()

    getReporteStockLiquidacion
      .execute()
      .then((reporteStock) => {
        CustomResponse.success({ res, data: reporteStock })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
