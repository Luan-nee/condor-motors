import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { DeclareVentaDto } from '@/domain/dtos/entities/facturacion/declare-venta.dto'
import { DeclareVenta } from '@/domain/use-cases/facturacion/declare-venta.use-case'
import type { BillingService } from '@/types/interfaces'
import type { Request, Response } from 'express'
import { SyncDocumentDto } from '@/domain/dtos/entities/facturacion/sync-document.dto'
import { SyncDocument } from '@/domain/use-cases/facturacion/sync-document.use-case'
import { CancelDocumentDto } from '@/domain/dtos/entities/facturacion/cancel-document.dto'
import { CancelDocument } from '@/domain/use-cases/facturacion/cancel-document.use-case'

export class FacturacionController {
  constructor(private readonly billingService: BillingService) {}

  declare = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    if (req.sucursalId === undefined) {
      CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
      return
    }

    const [error, declareVentaDto] = DeclareVentaDto.validate(req.body)
    if (error !== undefined || declareVentaDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload, sucursalId } = req

    const declareVenta = new DeclareVenta(authPayload, this.billingService)

    declareVenta
      .execute(declareVentaDto, sucursalId)
      .then((ventaDeclarada) => {
        CustomResponse.success({ res, data: ventaDeclarada })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  sync = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    if (req.sucursalId === undefined) {
      CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
      return
    }

    const [error, syncDocumentDto] = SyncDocumentDto.validate(req.body)
    if (error !== undefined || syncDocumentDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload, sucursalId } = req

    const syncDocument = new SyncDocument(authPayload, this.billingService)

    syncDocument
      .execute(syncDocumentDto, sucursalId)
      .then((documentoSincronizado) => {
        CustomResponse.success({ res, data: documentoSincronizado })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  anular = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    if (req.sucursalId === undefined) {
      CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
      return
    }

    const [error, cancelDocumentDto] = CancelDocumentDto.validate(req.body)
    if (error !== undefined || cancelDocumentDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload, sucursalId } = req

    const cancelDocument = new CancelDocument(authPayload, this.billingService)

    cancelDocument
      .execute(cancelDocumentDto, sucursalId)
      .then((documentoSincronizado) => {
        CustomResponse.success({ res, data: documentoSincronizado })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}
