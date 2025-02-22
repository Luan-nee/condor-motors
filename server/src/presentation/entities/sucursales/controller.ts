import { NumericIdDto } from '@/domain/dtos/entities/numeric-id.dto'
import { CreateSucursalDto } from '@/domain/dtos/entities/sucursales/create-sucursal.dto'
import { handleError } from '@/domain/errors/handle.error'
import { CreateSucursal } from '@/domain/use-cases/entities/sucursales/create-sucursal.use-case'
import { GetSucursal } from '@/domain/use-cases/entities/sucursales/get-sucursal.use-case'
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

    const getSucursal = new GetSucursal()

    getSucursal
      .execute(numericIdDto)
      .then((sucursal) => {
        res.status(200).json(sucursal)
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
