import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  clientesTable,
  detallesVentaTable,
  documentosTable,
  metodosPagoTable,
  monedasFacturacionTable,
  sucursalesTable,
  tiposDocumentoClienteTable,
  tiposDocumentoFacturacionTable,
  tiposTaxTable,
  totalesVentaTable,
  ventasTable
} from '@/db/schema'
import type { DeclareVentaDto } from '@/domain/dtos/entities/ventas/declare-venta.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { BillingService } from '@/types/interfaces'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq } from 'drizzle-orm'

export class DeclareVenta {
  private readonly authPayload: AuthPayload
  private readonly billingService: BillingService
  private readonly permissionAny = permissionCodes.ventas.declareAny
  private readonly permissionRelated = permissionCodes.ventas.declareRelated
  private readonly ventaSelectFields = {
    tipo_documento: tiposDocumentoFacturacionTable.codigo,
    serie: ventasTable.serieDocumento,
    numero: ventasTable.numeroDocumento,
    tipo_operacion: ventasTable.tipoOperacion,
    fecha_de_emision: ventasTable.fechaEmision,
    hora_de_emision: ventasTable.horaEmision,
    moneda: monedasFacturacionTable.codigo,
    porcentaje_de_venta: ventasTable.porcentajeVenta,
    datos_del_emisor: {
      codigo_establecimiento: sucursalesTable.codigoEstablecimiento
    },
    cliente_tipo_documento: tiposDocumentoClienteTable.codigo,
    cliente_numero_documento: clientesTable.numeroDocumento,
    cliente_denominacion: clientesTable.denominacion,
    codigo_pais: clientesTable.codigoPais,
    cliente_direccion: clientesTable.direccion,
    cliente_email: clientesTable.correo,
    cliente_telefono: clientesTable.telefono,
    total_gravadas: totalesVentaTable.totalGravadas,
    total_exoneradas: totalesVentaTable.totalExoneradas,
    total_gratuitas: totalesVentaTable.totalGratuitas,
    total_tax: totalesVentaTable.totalTax,
    total_venta: totalesVentaTable.totalVenta,
    termino_de_pago: {
      descripcion: metodosPagoTable.codigo,
      tipo: metodosPagoTable.tipo
    },
    observaciones: ventasTable.observaciones,
    declarada: ventasTable.declarada
  }
  private readonly detallesVentaSelectFields = {
    unidad: detallesVentaTable.tipoUnidad,
    codigo: detallesVentaTable.sku,
    descripcion: detallesVentaTable.nombre,
    cantidad: detallesVentaTable.cantidad,
    valor_unitario: detallesVentaTable.precioSinIgv,
    precio_unitario: detallesVentaTable.precioConIgv,
    tipo_tax: tiposTaxTable.codigo,
    total_base_tax: detallesVentaTable.totalBaseTax,
    total_tax: detallesVentaTable.totalTax,
    total: detallesVentaTable.total
  }

  constructor(authPayload: AuthPayload, billingService: BillingService) {
    this.authPayload = authPayload
    this.billingService = billingService
  }

  async getFormattedData(
    numericIdDto: NumericIdDto,
    declareVentaDto: DeclareVentaDto,
    sucursalId: SucursalIdType
  ) {
    const ventas = await db
      .select(this.ventaSelectFields)
      .from(ventasTable)
      .innerJoin(
        totalesVentaTable,
        eq(ventasTable.id, totalesVentaTable.ventaId)
      )
      .innerJoin(
        tiposDocumentoFacturacionTable,
        eq(ventasTable.tipoDocumentoId, tiposDocumentoFacturacionTable.id)
      )
      .innerJoin(
        monedasFacturacionTable,
        eq(ventasTable.monedaId, monedasFacturacionTable.id)
      )
      .innerJoin(
        metodosPagoTable,
        eq(ventasTable.metodoPagoId, metodosPagoTable.id)
      )
      .innerJoin(clientesTable, eq(ventasTable.clienteId, clientesTable.id))
      .innerJoin(
        tiposDocumentoClienteTable,
        eq(clientesTable.tipoDocumentoId, tiposDocumentoClienteTable.id)
      )
      .innerJoin(
        sucursalesTable,
        eq(ventasTable.sucursalId, sucursalesTable.id)
      )
      .where(
        and(
          eq(ventasTable.id, numericIdDto.id),
          eq(ventasTable.sucursalId, sucursalId)
        )
      )

    if (ventas.length < 1) {
      throw CustomError.notFound(
        `No se encontró la venta con id ${numericIdDto.id} en la sucursal especificada`
      )
    }

    const [venta] = ventas

    if (venta.datos_del_emisor.codigo_establecimiento === null) {
      throw CustomError.badRequest(
        `La sucursal que realizó la venta no posee un código de establecimiento, pero este es requerido para declarar una venta`
      )
    }

    if (venta.declarada) {
      throw CustomError.badRequest(
        'Esta venta no puede ser declarada (Ya ha sido declarada con anterioridad)'
      )
    }

    const detalles = await db
      .select(this.detallesVentaSelectFields)
      .from(detallesVentaTable)
      .innerJoin(
        tiposTaxTable,
        eq(detallesVentaTable.tipoTaxId, tiposTaxTable.id)
      )
      .where(eq(detallesVentaTable.ventaId, numericIdDto.id))

    const items: Item[] = detalles.map((detalle) => ({
      unidad: detalle.unidad,
      codigo: detalle.codigo,
      descripcion: detalle.descripcion,
      codigo_producto_sunat: '',
      codigo_producto_gsl: '',
      cantidad: detalle.cantidad,
      valor_unitario: parseFloat(detalle.valor_unitario),
      precio_unitario: parseFloat(detalle.precio_unitario),
      tipo_tax: detalle.tipo_tax,
      total_base_tax: parseFloat(detalle.total_base_tax),
      total_tax: parseFloat(detalle.total_tax),
      total: parseFloat(detalle.total)
    }))

    const document: DocumentoFacturacion = {
      tipo_documento: venta.tipo_documento,
      serie: venta.serie,
      numero: venta.numero,
      tipo_operacion: venta.tipo_operacion,
      fecha_de_emision: venta.fecha_de_emision,
      hora_de_emision: venta.hora_de_emision,
      moneda: venta.moneda,
      porcentaje_de_venta: venta.porcentaje_de_venta,
      fecha_de_vencimiento: '',
      enviar_automaticamente_al_cliente: declareVentaDto.enviarCliente,
      datos_del_emisor: {
        codigo_establecimiento: venta.datos_del_emisor.codigo_establecimiento
      },
      cliente: {
        cliente_tipo_documento: venta.cliente_tipo_documento,
        cliente_numero_documento: venta.cliente_numero_documento,
        cliente_denominacion: venta.cliente_denominacion,
        codigo_pais: '',
        ubigeo: '',
        cliente_direccion: venta.cliente_direccion ?? '',
        cliente_email: venta.cliente_email ?? '',
        cliente_telefono: venta.cliente_telefono ?? ''
      },
      totales: {
        total_exportacion: 0,
        total_gravadas: parseFloat(venta.total_gravadas),
        total_inafectas: 0,
        total_exoneradas: parseFloat(venta.total_exoneradas),
        total_gratuitas: parseFloat(venta.total_gratuitas),
        total_tax: parseFloat(venta.total_tax),
        total_venta: parseFloat(venta.total_venta)
      },
      items,
      acciones: {
        formato_pdf: 'a4'
      },
      termino_de_pago: {
        descripcion: venta.termino_de_pago.descripcion,
        tipo: venta.termino_de_pago.tipo
      },
      metodo_de_pago: '',
      canal_de_venta: '',
      orden_de_compra: '',
      almacen: '',
      observaciones: venta.observaciones ?? ''
    }

    return document
  }

  private async declareVenta(
    documentoFacturacion: DocumentoFacturacion,
    numericIdDto: NumericIdDto
  ) {
    const { data: documentDataResponse, error } =
      await this.billingService.sendDocument({
        document: documentoFacturacion
      })

    if (error !== null) {
      throw CustomError.badRequest(error.message)
    }

    return await db.transaction(async (tx) => {
      const [documento] = await tx
        .insert(documentosTable)
        .values({
          factproDocumentId: documentDataResponse.data.external_id,
          hash: documentDataResponse.data.hash,
          qr: documentDataResponse.data.qr,
          linkXml: documentDataResponse.links.xml,
          linkPdf: documentDataResponse.links.pdf,
          linkCdr: documentDataResponse.links.cdr,
          ventaId: numericIdDto.id
        })
        .returning({ id: documentosTable.id })

      const updatedResults = await tx
        .update(ventasTable)
        .set({ declarada: true })
        .where(eq(ventasTable.id, numericIdDto.id))
        .returning({ id: ventasTable.id })

      if (updatedResults.length < 1) {
        throw CustomError.internalServer(
          'Ha ocurrido un problema al intentar declarar la venta (Contacte a soporte técnico para resolver este problema)'
        )
      }

      return documento
    })
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

  async execute(
    numericIdDto: NumericIdDto,
    declareVentaDto: DeclareVentaDto,
    sucursalId: SucursalIdType
  ) {
    const documentoFacturacion = await this.getFormattedData(
      numericIdDto,
      declareVentaDto,
      sucursalId
    )

    const result = await this.declareVenta(documentoFacturacion, numericIdDto)

    return result
  }
}
