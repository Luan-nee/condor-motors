import { permissionCodes, tiposDocFacturacionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import {
  fixedTwoDecimals,
  getDateTimeString,
  getOffsetDateTime,
  productWithTwoDecimals,
  roundTwoDecimals
} from '@/core/lib/utils'
import { db } from '@/db/connection'
import {
  clientesTable,
  detallesProductoTable,
  detallesVentaTable,
  empleadosTable,
  metodosPagoTable,
  monedasFacturacionTable,
  productosTable,
  sucursalesTable,
  tiposDocumentoClienteTable,
  tiposDocumentoFacturacionTable,
  tiposTaxTable,
  totalesVentaTable,
  ventasTable
} from '@/db/schema'
import type { CreateVentaDto } from '@/domain/dtos/entities/ventas/create-venta.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, desc, eq, inArray } from 'drizzle-orm'

interface DetalleVenta {
  sku: string
  nombre: string
  cantidad: number
  precioSinIgv: string
  precioConIgv: string
  tipoTaxId: number
  totalBaseTax: string
  totalTax: string
  total: string
}

export class CreateVenta {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.ventas.createAny
  private readonly permissionRelated = permissionCodes.ventas.createRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async createVenta(
    createVentaDto: CreateVentaDto,
    sucursalId: SucursalIdType,
    serieDocumento: string
  ) {
    const { moneda, metodoPago } = await this.getDefaultMonedaMetodoPago()

    const { date, time } = this.getDateTime()

    const numeroDocumento = await this.getDocumentNumber(serieDocumento, 8)

    const tipoTaxIds = createVentaDto.detalles.map(
      (detalle) => detalle.tipoTaxId
    )

    const tiposTax = await db
      .select({
        id: tiposTaxTable.id,
        porcentajeTax: tiposTaxTable.porcentajeTax
      })
      .from(tiposTaxTable)
      .where(inArray(tiposTaxTable.id, tipoTaxIds))

    const tiposTaxMap = new Map(tiposTax.map((t) => [t.id, t]))

    const result = await db.transaction(async (tx) => {
      const productoIds = createVentaDto.detalles.map(
        (detalle) => detalle.productoId
      )

      const detallesProductos = await tx
        .select({
          id: detallesProductoTable.id,
          stock: detallesProductoTable.stock,
          precioVenta: detallesProductoTable.precioVenta,
          productoId: detallesProductoTable.productoId,
          sku: productosTable.sku,
          nombre: productosTable.nombre
        })
        .from(detallesProductoTable)
        .innerJoin(
          productosTable,
          eq(productosTable.id, detallesProductoTable.productoId)
        )
        .where(
          and(
            eq(detallesProductoTable.sucursalId, sucursalId),
            inArray(detallesProductoTable.productoId, productoIds)
          )
        )

      const detallesProductosMap = new Map(
        detallesProductos.map((p) => [p.productoId, p])
      )

      const detallesVenta: DetalleVenta[] = []
      let totalGravadas = 0
      let totalGratuitas = 0
      let totalExoneradas = 0
      let totalTax = 0
      let totalVenta = 0

      for (const detalleVenta of createVentaDto.detalles) {
        const detalleProducto = detallesProductosMap.get(
          detalleVenta.productoId
        )
        const tipoTaxProducto = tiposTaxMap.get(detalleVenta.tipoTaxId)

        if (detalleProducto === undefined) {
          throw CustomError.badRequest(
            `El producto con id ${detalleVenta.productoId} no existe en la sucursal especificada`
          )
        }
        if (tipoTaxProducto === undefined) {
          throw CustomError.badRequest(
            `El tipo de impuesto que intentó asignar al detalle con el producto ${detalleVenta.productoId} no existe`
          )
        }

        this.validateStock(detalleProducto, detalleVenta.cantidad)

        const detallesItem = this.computeDetallesItem(
          detalleProducto.precioVenta,
          detalleVenta.cantidad,
          tipoTaxProducto.porcentajeTax
        )

        detallesVenta.push({
          sku: detalleProducto.sku,
          nombre: detalleProducto.nombre,
          cantidad: detalleVenta.cantidad,
          precioSinIgv: fixedTwoDecimals(detallesItem.valorUnitario),
          precioConIgv: fixedTwoDecimals(detallesItem.precioUnitario),
          tipoTaxId: detalleVenta.tipoTaxId,
          totalBaseTax: fixedTwoDecimals(detallesItem.totalBaseTax),
          totalTax: fixedTwoDecimals(detallesItem.totalTax),
          total: fixedTwoDecimals(detallesItem.totalItem)
        })

        if (detallesItem.exonerada) {
          totalExoneradas += detallesItem.totalItem
        } else {
          totalGravadas += detallesItem.totalBaseTax
          totalTax += detallesItem.totalTax
        }

        totalGratuitas += detallesItem.totalGratuitas

        await tx
          .update(detallesProductoTable)
          .set({ stock: detalleProducto.stock - detalleVenta.cantidad })
          .where(eq(detallesProductoTable.id, detalleProducto.id))
      }

      const [venta] = await tx
        .insert(ventasTable)
        .values({
          serieDocumento,
          numeroDocumento,
          observaciones: createVentaDto.observaciones,
          tipoDocumentoId: createVentaDto.tipoDocumentoId,
          monedaId: moneda.id,
          metodoPagoId: metodoPago.id,
          clienteId: createVentaDto.clienteId,
          empleadoId: createVentaDto.empleadoId,
          sucursalId,
          fechaEmision: createVentaDto.fechaEmision ?? date,
          horaEmision: createVentaDto.horaEmision ?? time
        })
        .returning({ id: ventasTable.id })

      await tx
        .insert(detallesVentaTable)
        .values(
          detallesVenta.map((detalle) => ({ ...detalle, ventaId: venta.id }))
        )

      totalVenta = totalGravadas + totalExoneradas + totalTax

      await tx.insert(totalesVentaTable).values({
        totalGravadas: fixedTwoDecimals(totalGravadas),
        totalExoneradas: fixedTwoDecimals(totalExoneradas),
        totalGratuitas: fixedTwoDecimals(totalGratuitas),
        totalTax: fixedTwoDecimals(totalTax),
        totalVenta: fixedTwoDecimals(totalVenta),
        ventaId: venta.id
      })

      return venta
    })

    return result
  }

  private async getDocumentNumber(serieDocumento: string, fixedLength: number) {
    const documents = await db
      .select({ numeroDocumento: ventasTable.numeroDocumento })
      .from(ventasTable)
      .orderBy(desc(ventasTable.fechaCreacion))
      .where(eq(ventasTable.serieDocumento, serieDocumento))
      .limit(1)

    let nextDocumentNumber = 1

    if (documents.length > 0) {
      const [document] = documents
      nextDocumentNumber = parseInt(document.numeroDocumento) + 1
    }

    return nextDocumentNumber.toString().padStart(fixedLength, '0')
  }

  private async getDefaultMonedaMetodoPago() {
    const [moneda] = await db
      .select({ id: monedasFacturacionTable.id })
      .from(monedasFacturacionTable)
      .limit(1)

    const [metodoPago] = await db
      .select({ id: metodosPagoTable.id })
      .from(metodosPagoTable)
      .limit(1)

    return { moneda, metodoPago }
  }

  private validateStock(
    detalleProducto: { productoId: number; stock: number },
    cantidad: number
  ) {
    if (detalleProducto.stock < cantidad) {
      throw CustomError.badRequest(
        'Stock insuficiente para el producto ' + detalleProducto.productoId
      )
    }
  }

  private computeDetallesItem(
    precioVenta: string,
    cantidad: number,
    porcentajeTax: number | null
  ) {
    if (porcentajeTax === null) {
      throw CustomError.badRequest(
        'El tipo de impuesto que intentó asignar es inválido'
      )
    }

    const valorUnitario = parseFloat(precioVenta)
    const taxUnitario = valorUnitario * (porcentajeTax / 100)
    const precioUnitario = roundTwoDecimals(valorUnitario + taxUnitario)
    const totalBaseTax = productWithTwoDecimals(valorUnitario, cantidad)
    const totalTax = productWithTwoDecimals(taxUnitario, cantidad)
    const totalItem = roundTwoDecimals(totalBaseTax + totalTax)

    const exonerada = porcentajeTax === 0

    return {
      valorUnitario,
      precioUnitario,
      totalBaseTax,
      totalTax,
      totalItem,
      totalGratuitas: 0,
      exonerada
    }
  }

  private getDateTime() {
    const offsetTime = getOffsetDateTime(new Date(), -5)

    if (offsetTime === undefined) {
      throw CustomError.internalServer()
    }

    const { date, time } = getDateTimeString(offsetTime)
    return { date, time }
  }

  private async validateEntities(
    createVentaDto: CreateVentaDto,
    sucursalId: SucursalIdType
  ) {
    const results = await db
      .select({
        tipoDocumentoId: tiposDocumentoFacturacionTable.id,
        tipoDocumentoCodigo: tiposDocumentoFacturacionTable.codigoLocal,
        clienteId: clientesTable.id,
        tipoDocumentoClienteCodigo: tiposDocumentoClienteTable.codigo,
        direccionCliente: clientesTable.direccion,
        empleadoId: empleadosTable.id,
        sucursalId: sucursalesTable.id,
        serieFacturaSucursal: sucursalesTable.serieFacturaSucursal,
        serieBoletaSucursal: sucursalesTable.serieBoletaSucursal
      })
      .from(sucursalesTable)
      .leftJoin(
        tiposDocumentoFacturacionTable,
        eq(tiposDocumentoFacturacionTable.id, createVentaDto.tipoDocumentoId)
      )
      .leftJoin(clientesTable, eq(clientesTable.id, createVentaDto.clienteId))
      .leftJoin(
        tiposDocumentoClienteTable,
        eq(clientesTable.tipoDocumentoId, tiposDocumentoClienteTable.id)
      )
      .leftJoin(
        empleadosTable,
        eq(empleadosTable.id, createVentaDto.empleadoId)
      )
      .where(eq(sucursalesTable.id, sucursalId))

    if (results.length < 1) {
      throw CustomError.badRequest('La sucursal que intentó asignar no existe')
    }

    const [result] = results

    if (result.tipoDocumentoId === null) {
      throw CustomError.badRequest(
        'El tipo de documento que intentó asignar no existe'
      )
    }
    if (result.clienteId === null) {
      throw CustomError.badRequest('El cliente que intentó asignar no existe')
    }
    if (result.empleadoId === null) {
      throw CustomError.badRequest('El empleado que intentó asignar no existe')
    }

    this.validateClientDocument({
      tipoDocumentoClienteCodigo: result.tipoDocumentoClienteCodigo,
      tipoDocumentoCodigo: result.tipoDocumentoCodigo
    })

    return this.getSerieDocument(result)
  }

  private validateClientDocument(data: {
    tipoDocumentoClienteCodigo: string | null
    tipoDocumentoCodigo: string | null
  }) {
    if (
      data.tipoDocumentoCodigo === tiposDocFacturacionCodes.factura &&
      data.tipoDocumentoClienteCodigo === '1'
    ) {
      throw CustomError.badRequest(
        'No es posible emitir facturas para clientes con DNI, esto solo esta permitido para clientes con RUC'
      )
    }
  }

  private getSerieDocument(data: {
    tipoDocumentoCodigo: string | null
    serieFacturaSucursal: string | null
    serieBoletaSucursal: string | null
    direccionCliente: string | null
  }) {
    if (data.tipoDocumentoCodigo === tiposDocFacturacionCodes.factura) {
      if (data.serieFacturaSucursal !== null) {
        return data.serieFacturaSucursal
      }
      if (data.direccionCliente === null) {
        throw CustomError.badRequest(
          'La dirección del cliente es obligatoria para emitir facturas'
        )
      }
      throw CustomError.badRequest(
        'La sucursal especificada no tiene una serie definida para emitir facturas'
      )
    }
    if (data.tipoDocumentoCodigo === tiposDocFacturacionCodes.boleta) {
      if (data.serieBoletaSucursal !== null) {
        return data.serieBoletaSucursal
      }

      throw CustomError.badRequest(
        'La sucursal especificada no tiene una serie definida para emitir boletas'
      )
    }
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

  async execute(createVentaDto: CreateVentaDto, sucursalId: SucursalIdType) {
    await this.validatePermissions(sucursalId)

    const serieDocumento = await this.validateEntities(
      createVentaDto,
      sucursalId
    )

    if (serieDocumento === undefined) {
      throw CustomError.badRequest(
        'El tipo de documento de facturación especificado no se puede emitir en la sucursal especificada (No tiene una serie definida)'
      )
    }

    const results = await this.createVenta(
      createVentaDto,
      sucursalId,
      serieDocumento
    )

    return results
  }
}
