import { permissionCodes } from '@/consts'
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
  tiposDocumentoFacturacionTable,
  tiposTaxTable,
  totalesVentaTable,
  ventasTable
} from '@/db/schema'
import type { CreateVentaDto } from '@/domain/dtos/entities/ventas/create-venta.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq } from 'drizzle-orm'

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
  private readonly tokenFacturacion?: string
  private readonly permissionAny = permissionCodes.ventas.createAny
  private readonly permissionRelated = permissionCodes.ventas.createRelated

  constructor(authPayload: AuthPayload, tokenFacturacion?: string) {
    this.authPayload = authPayload
    this.tokenFacturacion = tokenFacturacion
  }

  private async registerVenta(
    createVentaDto: CreateVentaDto,
    sucursalId: SucursalIdType
  ) {
    const { moneda, metodoPago } = await this.getDefaultMonedaMetodoPago()

    const result = await db.transaction(async (tx) => {
      const detallesVenta: DetalleVenta[] = []
      let totalGravadas = 0
      let totalGratuitas = 0
      let totalExoneradas = 0
      let totalTax = 0
      let totalVenta = 0

      for (const detalleVenta of createVentaDto.detalles) {
        const detallesProducto = await tx
          .select({
            id: detallesProductoTable.id,
            stock: detallesProductoTable.stock,
            precioVenta: detallesProductoTable.precioVenta,
            productoId: detallesProductoTable.productoId
          })
          .from(detallesProductoTable)
          .where(
            and(
              eq(detallesProductoTable.productoId, detalleVenta.productoId),
              eq(detallesProductoTable.sucursalId, sucursalId)
            )
          )
          .for('update')
          .execute()

        if (detallesProducto.length < 1) {
          throw CustomError.badRequest(
            `El producto con id ${detalleVenta.productoId} no existe en la sucursal especificada`
          )
        }

        const [detalleProducto] = detallesProducto
        this.validateStock(detalleProducto, detalleVenta.cantidad)

        const productos = await tx
          .select({
            sku: productosTable.sku,
            nombre: productosTable.nombre,
            tipoTaxId: tiposTaxTable.id,
            porcentajeTax: tiposTaxTable.porcentajeTax
          })
          .from(productosTable)
          .where(eq(productosTable.id, detalleVenta.productoId))
          .leftJoin(tiposTaxTable, eq(tiposTaxTable.id, detalleVenta.tipoTaxId))
          .execute()

        if (productos.length < 1) {
          throw CustomError.badRequest(
            'Producto no encontrado ' + detalleVenta.productoId
          )
        }

        const [producto] = productos

        if (producto.tipoTaxId === null) {
          throw CustomError.badRequest(
            `El tipo de impuesto que intentó asignar al detalle con el producto ${detalleVenta.productoId} no existe`
          )
        }

        const detallesItem = this.computeDetallesItem(
          detalleProducto.precioVenta,
          detalleVenta.cantidad,
          producto.porcentajeTax
        )

        detallesVenta.push({
          sku: producto.sku,
          nombre: producto.nombre,
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
          .execute()
      }

      const { date, time } = this.getDateTime()

      const [venta] = await tx
        .insert(ventasTable)
        .values({
          observaciones: createVentaDto.observaciones,
          tipoDocumentoId: createVentaDto.tipoDocumentoId,
          monedaId: moneda.id,
          metodoPagoId: metodoPago.id,
          clienteId: createVentaDto.clienteId,
          empleadoId: createVentaDto.empleadoId,
          sucursalId,
          fechaEmision: createVentaDto.documento?.fechaEmision ?? date,
          horaEmision: createVentaDto.documento?.horaEmision ?? time
        })
        .returning({ id: ventasTable.id })

      await tx
        .insert(detallesVentaTable)
        .values(
          detallesVenta.map((detalle) => ({ ...detalle, ventaId: venta.id }))
        )
        .execute()

      totalVenta = totalGravadas + totalExoneradas + totalTax

      await tx
        .insert(totalesVentaTable)
        .values({
          totalGravadas: fixedTwoDecimals(totalGravadas),
          totalExoneradas: fixedTwoDecimals(totalExoneradas),
          totalGratuitas: fixedTwoDecimals(totalGratuitas),
          totalTax: fixedTwoDecimals(totalTax),
          totalVenta: fixedTwoDecimals(totalVenta),
          ventaId: venta.id
        })
        .execute()

      return venta
    })

    return result
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
        clienteId: clientesTable.id,
        empleadoId: empleadosTable.id,
        sucursalId: sucursalesTable.id
      })
      .from(sucursalesTable)
      .leftJoin(
        tiposDocumentoFacturacionTable,
        eq(tiposDocumentoFacturacionTable.id, createVentaDto.tipoDocumentoId)
      )
      .leftJoin(clientesTable, eq(clientesTable.id, createVentaDto.clienteId))
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
  }

  private validateDuplicated(createVentaDto: CreateVentaDto) {
    const productoIds = new Set<number>()
    const duplicateProductoIds = new Set<number>()

    for (const { productoId } of createVentaDto.detalles) {
      if (productoIds.has(productoId)) {
        duplicateProductoIds.add(productoId)
      } else {
        productoIds.add(productoId)
      }
    }

    if (duplicateProductoIds.size > 0) {
      throw CustomError.badRequest(
        `Existen productos duplicados en los detalles: ${[...duplicateProductoIds].join(', ')}`
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
    this.validateDuplicated(createVentaDto)

    await this.validateEntities(createVentaDto, sucursalId)

    const results = await this.registerVenta(createVentaDto, sucursalId)

    return results
  }
}
