import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  clientesTable,
  detallesVentaTable,
  empleadosTable,
  metodosPagoTable,
  monedasFacturacionTable,
  sucursalesTable,
  tiposDocumentoClienteTable,
  tiposDocumentoFacturacionTable,
  tiposTaxTable,
  totalesVentaTable,
  ventasTable
} from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq } from 'drizzle-orm'

export class GetVentaById {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.ventas.getAny
  private readonly permissionRelated = permissionCodes.ventas.getRelated
  private readonly ventaSelectFields = {
    id: ventasTable.id,
    serieDocumento: ventasTable.serieDocumento,
    numeroDocumento: ventasTable.numeroDocumento,
    observaciones: ventasTable.observaciones,
    tipoDocumento: tiposDocumentoFacturacionTable.nombre,
    fechaEmision: ventasTable.fechaEmision,
    horaEmision: ventasTable.horaEmision,
    moneda: monedasFacturacionTable.nombre,
    metodoPago: metodosPagoTable.nombre,
    cliente: {
      id: clientesTable.id,
      tipoDocumento: tiposDocumentoClienteTable.nombre,
      numeroDocumento: clientesTable.numeroDocumento,
      denominacion: clientesTable.denominacion,
      codigoPais: clientesTable.codigoPais
    },
    empleado: {
      id: empleadosTable.id,
      nombre: empleadosTable.nombre,
      apellidos: empleadosTable.apellidos
    },
    sucursal: {
      id: sucursalesTable.id,
      nombre: sucursalesTable.nombre
    },
    totalesVenta: {
      totalGravadas: totalesVentaTable.totalGravadas,
      totalExoneradas: totalesVentaTable.totalExoneradas,
      totalGratuitas: totalesVentaTable.totalGratuitas,
      totalTax: totalesVentaTable.totalTax,
      totalVenta: totalesVentaTable.totalVenta
    }
  }
  private readonly detallesVentaSelectFields = {
    id: detallesVentaTable.id,
    tipoUnidad: detallesVentaTable.tipoUnidad,
    sku: detallesVentaTable.sku,
    nombre: detallesVentaTable.nombre,
    cantidad: detallesVentaTable.cantidad,
    precioSinIgv: detallesVentaTable.precioSinIgv,
    precioConIgv: detallesVentaTable.precioConIgv,
    tipoTax: tiposTaxTable.nombre,
    totalBaseTax: detallesVentaTable.totalBaseTax,
    totalTax: detallesVentaTable.totalTax,
    total: detallesVentaTable.total,
    ventaId: detallesVentaTable.ventaId
  }

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async getVenta(
    numericIdDto: NumericIdDto,
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
      .innerJoin(empleadosTable, eq(ventasTable.empleadoId, empleadosTable.id))
      .innerJoin(
        sucursalesTable,
        eq(ventasTable.sucursalId, sucursalesTable.id)
      )
      .innerJoin(clientesTable, eq(ventasTable.clienteId, clientesTable.id))
      .innerJoin(
        tiposDocumentoClienteTable,
        eq(clientesTable.tipoDocumentoId, tiposDocumentoClienteTable.id)
      )
      .where(
        and(
          eq(ventasTable.id, numericIdDto.id),
          eq(ventasTable.sucursalId, sucursalId)
        )
      )

    if (ventas.length < 1) {
      throw CustomError.notFound('La venta no se encontró')
    }

    const [venta] = ventas

    const detallesVenta = await db
      .select(this.detallesVentaSelectFields)
      .from(detallesVentaTable)
      .innerJoin(
        tiposTaxTable,
        eq(detallesVentaTable.tipoTaxId, tiposTaxTable.id)
      )
      .where(eq(detallesVentaTable.ventaId, venta.id))

    return {
      ...venta,
      detallesVenta
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

  async execute(numericIdDto: NumericIdDto, sucursalId: SucursalIdType) {
    await this.validatePermissions(sucursalId)

    const venta = await this.getVenta(numericIdDto, sucursalId)

    return venta
  }
}
