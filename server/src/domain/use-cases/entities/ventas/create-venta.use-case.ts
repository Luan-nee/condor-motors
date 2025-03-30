/* eslint-disable max-lines */
import {
  permissionCodes,
  tiposDocClienteCodes,
  tiposDocFacturacionCodes,
  tiposTaxCodes
} from '@/consts'
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
  tiposDocFacturacionTable,
  tiposTaxTable,
  totalesVentaTable,
  ventasTable
} from '@/db/schema'
import type { CreateVentaDto } from '@/domain/dtos/entities/ventas/create-venta.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, desc, eq, inArray, like, or } from 'drizzle-orm'

interface DetalleVenta {
  codigo?: string
  nombre: string
  cantidad: number
  precioSinIgv: string
  precioConIgv: string
  tipoTaxId: number
  totalBaseTax: string
  totalTax: string
  total: string
  productoId?: number
}

interface ComputePriceOfferArgs {
  cantidad: number
  cantidadMinimaDescuento: number | null
  cantidadGratisDescuento: number | null
  porcentajeDescuento: number | null
  precioVenta: string
  precioOferta: string | null
  liquidacion: boolean
  aplicarOferta: boolean
}

interface ComputeTotalArgs {
  isFreeItem: boolean
  totalItem: number
  totalTaxItem: number
  totalBaseTaxItem: number
  exonerada: boolean
}

interface ComputeItemVentaDetailsArgs {
  detalleVenta: {
    productoId: number
    cantidad: number
    tipoTaxId: number
    aplicarOferta: boolean
  }
  detalleProducto: {
    id: number
    stock: number
    precioVenta: string
    precioOferta: string | null
    productoId: number
    sku: string
    nombre: string
    cantidadMinimaDescuento: number | null
    cantidadGratisDescuento: number | null
    porcentajeDescuento: number | null
    liquidacion: boolean
  }
  tipoTaxProducto: {
    id: number
    porcentajeTax: number
  }
  freeItemTax: {
    id: number
    codigoLocal: string
    porcentajeTax: number
  }
  applyOffer: boolean
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
    const { moneda, metodoPago, freeItemTax } = await this.getDefaultIds()

    const { date, time } = this.getDateTime()

    const numeroDocumento = await this.getDocumentNumber(serieDocumento, 8)

    const tipoTaxIds = createVentaDto.detalles.map(
      (detalle) => detalle.tipoTaxId
    )

    const tiposTax = await db
      .select({
        id: tiposTaxTable.id,
        porcentajeTax: tiposTaxTable.porcentaje
      })
      .from(tiposTaxTable)
      .where(inArray(tiposTaxTable.id, tipoTaxIds))

    const tiposTaxMap = new Map(tiposTax.map((t) => [t.id, t]))

    const productoIds = createVentaDto.detalles
      .map((detalle) => detalle.productoId)
      .filter((id) => id != null)

    const result = await db.transaction(async (tx) => {
      const detallesProductos = await tx
        .select({
          id: detallesProductoTable.id,
          stock: detallesProductoTable.stock,
          precioVenta: detallesProductoTable.precioVenta,
          precioOferta: detallesProductoTable.precioOferta,
          productoId: detallesProductoTable.productoId,
          sku: productosTable.sku,
          nombre: productosTable.nombre,
          cantidadMinimaDescuento: productosTable.cantidadMinimaDescuento,
          cantidadGratisDescuento: productosTable.cantidadGratisDescuento,
          porcentajeDescuento: productosTable.porcentajeDescuento,
          liquidacion: detallesProductoTable.liquidacion
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
        const tipoTaxProducto = tiposTaxMap.get(detalleVenta.tipoTaxId)

        if (tipoTaxProducto === undefined) {
          throw CustomError.badRequest(
            `El tipo de impuesto que intentó asignar al detalle con el producto ${detalleVenta.productoId} no existe`
          )
        }

        const isFreeItem = detalleVenta.tipoTaxId === freeItemTax.id

        if (detalleVenta.productoId == null) {
          const { detallesItem, item } = this.computeCustomItemVentaDetails({
            nombre: detalleVenta.nombre,
            price: detalleVenta.precio,
            cantidad: detalleVenta.cantidad,
            tipoTaxProducto
          })

          detallesVenta.push(item)

          const totalesItem = this.computeNewTotal({
            isFreeItem,
            totalItem: detallesItem.totalItem,
            totalTaxItem: detallesItem.totalTax,
            totalBaseTaxItem: detallesItem.totalBaseTax,
            exonerada: detallesItem.exonerada
          })

          totalGratuitas += totalesItem.totalGratuitas
          totalExoneradas += totalesItem.totalExoneradas
          totalGravadas += totalesItem.totalGravadas
          totalTax += totalesItem.totalTax

          continue
        }

        const detalleProducto = detallesProductosMap.get(
          detalleVenta.productoId
        )

        if (detalleProducto === undefined) {
          throw CustomError.badRequest(
            `El producto con id ${detalleVenta.productoId} no existe en la sucursal especificada`
          )
        }

        const applyOffer = detalleVenta.aplicarOferta && !isFreeItem

        const { detallesItem, items, totalGratuitasItem } =
          this.computeItemVentaDetails({
            detalleVenta,
            detalleProducto,
            tipoTaxProducto,
            freeItemTax,
            applyOffer
          })

        detallesVenta.push(...items)

        const totalesItem = this.computeNewTotal({
          isFreeItem,
          totalItem: detallesItem.totalItem,
          totalTaxItem: detallesItem.totalTax,
          totalBaseTaxItem: detallesItem.totalBaseTax,
          exonerada: detallesItem.exonerada
        })

        totalGratuitas += totalesItem.totalGratuitas + totalGratuitasItem
        totalExoneradas += totalesItem.totalExoneradas
        totalGravadas += totalesItem.totalGravadas
        totalTax += totalesItem.totalTax

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

  private computeItemVentaDetails({
    detalleVenta,
    detalleProducto,
    tipoTaxProducto,
    freeItemTax,
    applyOffer
  }: ComputeItemVentaDetailsArgs) {
    let { cantidad: newCantidad } = detalleVenta

    const { price, free } = this.computePriceOffer({
      cantidad: newCantidad,
      cantidadMinimaDescuento: detalleProducto.cantidadMinimaDescuento,
      cantidadGratisDescuento: detalleProducto.cantidadGratisDescuento,
      porcentajeDescuento: detalleProducto.porcentajeDescuento,
      precioVenta: detalleProducto.precioVenta,
      precioOferta: detalleProducto.precioOferta,
      liquidacion: detalleProducto.liquidacion,
      aplicarOferta: applyOffer
    })

    const detallesItem = this.computeDetallesItem(
      price,
      newCantidad,
      tipoTaxProducto.porcentajeTax
    )

    const items = [
      {
        codigo: detalleProducto.sku,
        nombre: detalleProducto.nombre,
        cantidad: newCantidad,
        precioSinIgv: fixedTwoDecimals(detallesItem.valorUnitario),
        precioConIgv: fixedTwoDecimals(detallesItem.precioUnitario),
        tipoTaxId: detalleVenta.tipoTaxId,
        totalBaseTax: fixedTwoDecimals(detallesItem.totalBaseTax),
        totalTax: fixedTwoDecimals(detallesItem.totalTax),
        total: fixedTwoDecimals(detallesItem.totalItem),
        productoId: detalleProducto.productoId
      }
    ]

    let totalGratuitasItem = 0

    if (free > 0 && applyOffer) {
      const detallesFreeItem = this.computeDetallesItem(
        price,
        free,
        freeItemTax.porcentajeTax
      )

      items.push({
        codigo: detalleProducto.sku,
        nombre: detalleProducto.nombre,
        cantidad: free,
        precioSinIgv: fixedTwoDecimals(detallesFreeItem.valorUnitario),
        precioConIgv: fixedTwoDecimals(detallesFreeItem.precioUnitario),
        tipoTaxId: freeItemTax.id,
        totalBaseTax: fixedTwoDecimals(detallesFreeItem.totalBaseTax),
        totalTax: fixedTwoDecimals(detallesFreeItem.totalTax),
        total: fixedTwoDecimals(detallesFreeItem.totalItem),
        productoId: detalleProducto.productoId
      })

      totalGratuitasItem += detallesFreeItem.totalItem
      newCantidad += free
    }

    this.validateStock(detalleProducto, newCantidad)

    return {
      detallesItem,
      price,
      free,
      items,
      totalGratuitasItem
    }
  }

  private computeCustomItemVentaDetails({
    nombre,
    price,
    cantidad,
    tipoTaxProducto
  }: {
    nombre: string
    price: number
    cantidad: number
    tipoTaxProducto: {
      id: number
      porcentajeTax: number
    }
  }) {
    const detallesItem = this.computeDetallesItem(
      price,
      cantidad,
      tipoTaxProducto.porcentajeTax
    )

    const item = {
      nombre,
      cantidad,
      precioSinIgv: fixedTwoDecimals(detallesItem.valorUnitario),
      precioConIgv: fixedTwoDecimals(detallesItem.precioUnitario),
      tipoTaxId: tipoTaxProducto.id,
      totalBaseTax: fixedTwoDecimals(detallesItem.totalBaseTax),
      totalTax: fixedTwoDecimals(detallesItem.totalTax),
      total: fixedTwoDecimals(detallesItem.totalItem)
    }

    return {
      detallesItem,
      item
    }
  }

  private computeNewTotal({
    isFreeItem,
    totalItem,
    totalTaxItem,
    totalBaseTaxItem,
    exonerada
  }: ComputeTotalArgs) {
    if (isFreeItem) {
      return {
        totalGratuitas: totalItem,
        totalExoneradas: 0,
        totalGravadas: 0,
        totalTax: 0
      }
    }

    if (exonerada) {
      return {
        totalGratuitas: 0,
        totalExoneradas: totalItem,
        totalGravadas: 0,
        totalTax: 0
      }
    }

    return {
      totalGratuitas: 0,
      totalExoneradas: 0,
      totalGravadas: totalBaseTaxItem,
      totalTax: totalTaxItem
    }
  }

  private async getDocumentNumber(serieDocumento: string, fixedLength: number) {
    const documents = await db
      .select({
        numeroDocumento: ventasTable.numeroDocumento
      })
      .from(ventasTable)
      .orderBy(desc(ventasTable.fechaCreacion))
      .where(eq(ventasTable.serieDocumento, serieDocumento))
      .limit(1)

    let nextDocumentNumber = 1

    if (documents.length > 0) {
      const [document] = documents
      nextDocumentNumber = parseInt(document.numeroDocumento) + 1
    } else {
      const sucursales = await db
        .select({
          numeroFacturaInicial: sucursalesTable.numeroFacturaInicial,
          numeroBoletaInicial: sucursalesTable.numeroBoletaInicial
        })
        .from(sucursalesTable)
        .where(
          or(
            like(sucursalesTable.serieFactura, serieDocumento),
            like(sucursalesTable.serieBoleta, serieDocumento)
          )
        )

      if (sucursales.length < 1) {
        throw CustomError.badRequest(
          'No se encontró una serie de documento para registrar la venta en la sucursal especificada'
        )
      }

      const [{ numeroFacturaInicial, numeroBoletaInicial }] = sucursales

      if (serieDocumento.startsWith('F') && numeroFacturaInicial !== null) {
        nextDocumentNumber = numeroFacturaInicial
      } else if (
        serieDocumento.startsWith('B') &&
        numeroBoletaInicial !== null
      ) {
        nextDocumentNumber = numeroBoletaInicial
      }
    }

    return nextDocumentNumber.toString().padStart(fixedLength, '0')
  }

  private async getDefaultIds() {
    const [moneda] = await db
      .select({ id: monedasFacturacionTable.id })
      .from(monedasFacturacionTable)
      .limit(1)

    const [metodoPago] = await db
      .select({ id: metodosPagoTable.id })
      .from(metodosPagoTable)
      .limit(1)

    const [freeItemTax] = await db
      .select({
        id: tiposTaxTable.id,
        codigoLocal: tiposTaxTable.codigo,
        porcentajeTax: tiposTaxTable.porcentaje
      })
      .from(tiposTaxTable)
      .where(eq(tiposTaxTable.codigo, tiposTaxCodes.gratuito))

    return { moneda, metodoPago, freeItemTax }
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

  private computePriceOffer({
    cantidad,
    cantidadMinimaDescuento,
    cantidadGratisDescuento,
    porcentajeDescuento,
    precioVenta,
    precioOferta,
    liquidacion,
    aplicarOferta
  }: ComputePriceOfferArgs) {
    let price = parseFloat(precioVenta)
    let free = 0

    if (!aplicarOferta) {
      return { price, free }
    }

    if (precioOferta !== null && liquidacion) {
      price = parseFloat(precioOferta)
    }

    if (
      cantidadMinimaDescuento === null ||
      cantidad < cantidadMinimaDescuento
    ) {
      return { price, free }
    }

    if (cantidadGratisDescuento !== null) {
      free = cantidadGratisDescuento
    } else if (porcentajeDescuento !== null) {
      price = productWithTwoDecimals(price, 1 - porcentajeDescuento / 100)
    }

    return {
      price,
      free
    }
  }

  private computeDetallesItem(
    precioVenta: number,
    cantidad: number,
    porcentajeTax: number | null
  ) {
    if (porcentajeTax === null) {
      throw CustomError.badRequest(
        'El tipo de impuesto que intentó asignar es inválido'
      )
    }

    const valorUnitario = precioVenta
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
        tipoDocumentoId: tiposDocFacturacionTable.id,
        tipoDocumentoCodigo: tiposDocFacturacionTable.codigo,
        clienteId: clientesTable.id,
        numeroDocCliente: clientesTable.numeroDocumento,
        tipoDocClienteCodigo: tiposDocumentoClienteTable.codigo,
        direccionCliente: clientesTable.direccion,
        empleadoId: empleadosTable.id,
        sucursalId: sucursalesTable.id,
        serieFacturaSucursal: sucursalesTable.serieFactura,
        serieBoletaSucursal: sucursalesTable.serieBoleta
      })
      .from(sucursalesTable)
      .leftJoin(
        tiposDocFacturacionTable,
        eq(tiposDocFacturacionTable.id, createVentaDto.tipoDocumentoId)
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
      tipoDocClienteCodigo: result.tipoDocClienteCodigo,
      tipoDocCodigo: result.tipoDocumentoCodigo,
      numeroDocCliente: result.numeroDocCliente
    })

    return this.getSerieDocument(result)
  }

  private validateClientDocument(data: {
    tipoDocClienteCodigo: string | null
    tipoDocCodigo: string | null
    numeroDocCliente: string | null
  }) {
    if (
      data.tipoDocCodigo === tiposDocFacturacionCodes.factura &&
      data.tipoDocClienteCodigo !== tiposDocClienteCodes.ruc
    ) {
      throw CustomError.badRequest(
        'Solo se pueden emitir facturas para clientes con RUC, no se permiten otros tipos de documentos'
      )
    }

    if (
      data.tipoDocCodigo === tiposDocFacturacionCodes.boleta &&
      data.tipoDocClienteCodigo === tiposDocClienteCodes.ruc
    ) {
      if (
        data.numeroDocCliente != null &&
        !data.numeroDocCliente.startsWith('10')
      ) {
        throw CustomError.badRequest(
          'No se pueden emitir boletas para clientes con RUC 20, solo se permiten otros tipos de documentos'
        )
      }
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
