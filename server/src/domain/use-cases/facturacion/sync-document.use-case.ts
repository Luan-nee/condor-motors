import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { tiposDocFacturacionTable, ventasTable } from '@/db/schema'
import type { SyncDocumentDto } from '@/domain/dtos/entities/facturacion/sync-document.dto'
import type { BillingService } from '@/types/interfaces'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq } from 'drizzle-orm'

export class SyncDocument {
  private readonly authPayload: AuthPayload
  private readonly billingService: BillingService
  private readonly permissionAny = permissionCodes.facturacion.syncAny
  private readonly permissionRelated = permissionCodes.facturacion.syncRelated

  constructor(authPayload: AuthPayload, billingService: BillingService) {
    this.authPayload = authPayload
    this.billingService = billingService
  }

  async getDocument(
    syncDocumentDto: SyncDocumentDto,
    sucursalId: SucursalIdType
  ) {
    const ventas = await db
      .select({
        serie: ventasTable.serieDocumento,
        numero: ventasTable.numeroDocumento,
        tipo_documento: tiposDocFacturacionTable.codigoSunat
      })
      .from(ventasTable)
      .innerJoin(
        tiposDocFacturacionTable,
        eq(ventasTable.tipoDocumentoId, tiposDocFacturacionTable.id)
      )
      .where(
        and(
          eq(ventasTable.id, syncDocumentDto.ventaId),
          eq(ventasTable.sucursalId, sucursalId)
        )
      )

    if (ventas.length < 1) {
      throw CustomError.notFound(
        `No se encontró la venta con id ${syncDocumentDto.ventaId} en la sucursal especificada`
      )
    }

    const [venta] = ventas

    return venta
  }

  async syncDocument(
    _syncDocumentDto: SyncDocumentDto,
    consultDocument: ConsultDocument
  ) {
    const { data: documentDataResponse, error } =
      await this.billingService.consultDocument({
        document: consultDocument
      })

    if (error !== null) {
      throw CustomError.badGateway(error.message)
    }

    // const estados = await db
    //   .select({ id: estadosDocumentoFacturacion.id })
    //   .from(estadosDocumentoFacturacion)
    //   .where(
    //     eq(
    //       estadosDocumentoFacturacion.codigo,
    //       documentDataResponse.data.state_type_id
    //     )
    //   )

    // let estado = undefined

    // if (estados.length > 0) {
    //   ;[estado] = estados
    // }

    return documentDataResponse

    // return await db.transaction(async (tx) => {
    //   const [documento] = await tx
    //     .insert(documentosFacturacionTable)
    //     .values({
    //       factproFilename: documentDataResponse.data.filename,
    //       factproDocumentId: documentDataResponse.data.external_id,
    //       hash: documentDataResponse.data.hash,
    //       qr: documentDataResponse.data.qr,
    //       linkXml: documentDataResponse.links.xml,
    //       linkPdf: documentDataResponse.links.pdf,
    //       linkCdr: documentDataResponse.links.cdr,
    //       estadoRawId: documentDataResponse.data.state_type_id,
    //       estadoId: estado?.id,
    //       informacionSunat: documentDataResponse.sunat_information,
    //       ventaId: declareVentaDto.ventaId
    //     })
    //     .returning({ id: documentosFacturacionTable.id })

    //   const updatedResults = await tx
    //     .update(ventasTable)
    //     .set({ declarada: true })
    //     .where(eq(ventasTable.id, declareVentaDto.ventaId))
    //     .returning({ id: ventasTable.id })

    //   if (updatedResults.length < 1) {
    //     throw CustomError.internalServer(
    //       'Ha ocurrido un problema al intentar declarar la venta (Contacte a soporte técnico para resolver este problema)'
    //     )
    //   }

    //   return documento
    // })
  }

  private async validatePermissions(sucursalId: SucursalIdType) {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny, this.permissionRelated]
    )

    let hasPermissionAny = false
    let hasPermissionRelated = false
    let isSameSucursal = false

    for (const permission of validPermissions) {
      if (permission.codigoPermiso === this.permissionAny) {
        hasPermissionAny = true
      }
      if (permission.codigoPermiso === this.permissionRelated) {
        hasPermissionRelated = true
      }
      if (permission.sucursalId === sucursalId) {
        isSameSucursal = true
      }

      if (hasPermissionAny || (hasPermissionRelated && isSameSucursal)) {
        return
      }
    }

    throw CustomError.forbidden()
  }

  async execute(syncDocumentDto: SyncDocumentDto, sucursalId: SucursalIdType) {
    await this.validatePermissions(sucursalId)

    const document = await this.getDocument(syncDocumentDto, sucursalId)

    const result = await this.syncDocument(syncDocumentDto, document)

    return result
  }
}
