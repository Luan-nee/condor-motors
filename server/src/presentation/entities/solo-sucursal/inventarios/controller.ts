import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { EntradaInventarioDto } from '@/domain/dtos/entities/inventarios/entradas.dto'
import { EntradaInventario } from '@/domain/use-cases/entities/inventarios/entrada-inventario.use-case'
import type { Request, Response } from 'express'

export class InventariosController {
  entradas = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    if (req.sucursalId === undefined) {
      CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
      return
    }

    const [error, createProductoDto] = EntradaInventarioDto.validate(req.body)

    if (error !== undefined || createProductoDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload, sucursalId } = req

    const createEntradaInventario = new EntradaInventario(authPayload)

    createEntradaInventario
      .execute(createProductoDto, sucursalId)
      .then((entradaInventario) => {
        CustomResponse.created({ res, data: entradaInventario })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  // getById = (req: Request, res: Response) => {
  //   if (req.authPayload === undefined) {
  //     CustomResponse.unauthorized({ res })
  //     return
  //   }

  //   if (req.sucursalId === undefined) {
  //     CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
  //     return
  //   }

  //   CustomResponse.notImplemented({ res })
  // }

  // getAll = (req: Request, res: Response) => {
  //   if (req.authPayload === undefined) {
  //     CustomResponse.unauthorized({ res })
  //     return
  //   }

  //   if (req.sucursalId === undefined) {
  //     CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
  //     return
  //   }

  //   CustomResponse.notImplemented({ res })
  // }

  // update = (req: Request, res: Response) => {
  //   if (req.authPayload === undefined) {
  //     CustomResponse.unauthorized({ res })
  //     return
  //   }

  //   if (req.sucursalId === undefined) {
  //     CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
  //     return
  //   }

  //   CustomResponse.notImplemented({ res })
  // }

  // delete = (req: Request, res: Response) => {
  //   if (req.authPayload === undefined) {
  //     CustomResponse.unauthorized({ res })
  //     return
  //   }

  //   CustomResponse.notImplemented({ res })
  // }

  // all = (req: Request, res: Response) => {
  //   if (req.authPayload === undefined) {
  //     CustomResponse.unauthorized({ res })
  //     return
  //   }

  //   CustomResponse.notImplemented({ res })
  // }
}
