import { CreateSucursalDto } from '@/domain/dtos/entities/sucursales/create-sucursal.dto'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { handleError } from '@/domain/errors/handle.error'
import { CreateSucursal } from '@/domain/use-cases/entities/sucursales/create-sucursal.use-case'
import { GetSucursalById } from '@/domain/use-cases/entities/sucursales/get-sucursal-by-id.use-case'
import { GetSucursales } from '@/domain/use-cases/entities/sucursales/get-sucursales.use-case'
import type { Request, Response } from 'express'

export class SucursalesController {
  // eslint-disable-next-line @typescript-eslint/class-methods-use-this
  create = (req: Request, res: Response) => {
    const [error, createSucursalDto] = CreateSucursalDto.create(req.body)
    if (error !== undefined || createSucursalDto === undefined) {
      res.status(400).json({ error: JSON.parse(error ?? '') })
      return
    }

    if (req.authPayload === undefined) {
      res.status(401).json({ error: 'Missing id' })
    }

    const createSucursal = new CreateSucursal()

    createSucursal
      .execute(createSucursalDto)
      .then((sucursal) => {
        res.status(200).json(sucursal)
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  // eslint-disable-next-line @typescript-eslint/class-methods-use-this
  getById = (req: Request, res: Response) => {
    const [error, numericIdDto] = NumericIdDto.create(req.params)

    if (error !== undefined || numericIdDto === undefined) {
      res.status(400).json({ error: 'Id inválido' })
      return
    }

    if (req.authPayload === undefined) {
      res.status(401).json({ error: 'Missing id' })
    }

    const getSucursalById = new GetSucursalById()

    getSucursalById
      .execute(numericIdDto)
      .then((sucursal) => {
        res.status(200).json(sucursal)
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  // eslint-disable-next-line @typescript-eslint/class-methods-use-this
  getAll = (req: Request, res: Response) => {
    const [error, queriesDto] = QueriesDto.create(req.query)

    if (error !== undefined || queriesDto === undefined) {
      res.status(400).json({ error: JSON.parse(error ?? '') })
      return
    }

    if (req.authPayload === undefined) {
      res.status(401).json({ error: 'Missing id' })
    }

    const getSucursales = new GetSucursales()

    getSucursales
      .execute(queriesDto)
      .then((sucursales) => {
        res.status(200).json(sucursales)
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
