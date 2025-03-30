import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  docsFacturacionTable,
  empleadosTable,
  estadosDocFacturacionTable,
  sucursalesTable,
  tiposDocFacturacionTable,
  totalesVentaTable,
  ventasTable
} from '@/db/schema'
import type { SucursalIdType } from '@/types/schemas'
import { eq } from 'drizzle-orm'

export class GetVentas {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.ventas.createAny
  private readonly permissionRelated = permissionCodes.ventas.createRelated
  private readonly selectFields = {
    id: ventasTable.id,
    declarada: ventasTable.declarada,
    anulada: ventasTable.anulada,
    serieDocumento: ventasTable.serieDocumento,
    numeroDocumento: ventasTable.numeroDocumento,
    tipoDocumento: tiposDocFacturacionTable.nombre,
    fechaEmision: ventasTable.fechaEmision,
    horaEmision: ventasTable.horaEmision,
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
    },
    estado: estadosDocFacturacionTable.nombre,
    documentoFacturacion: {
      id: docsFacturacionTable.id,
      codigoEstadoSunat: docsFacturacionTable.estadoRawId,
      linkPdf: docsFacturacionTable.linkPdf
    }
  }

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async getVentas(sucursalId: SucursalIdType) {
    const ventas = await db
      .select(this.selectFields)
      .from(ventasTable)
      .innerJoin(
        totalesVentaTable,
        eq(ventasTable.id, totalesVentaTable.ventaId)
      )
      .innerJoin(
        tiposDocFacturacionTable,
        eq(ventasTable.tipoDocumentoId, tiposDocFacturacionTable.id)
      )
      .innerJoin(empleadosTable, eq(ventasTable.empleadoId, empleadosTable.id))
      .innerJoin(
        sucursalesTable,
        eq(ventasTable.sucursalId, sucursalesTable.id)
      )
      .leftJoin(
        docsFacturacionTable,
        eq(ventasTable.id, docsFacturacionTable.ventaId)
      )
      .leftJoin(
        estadosDocFacturacionTable,
        eq(docsFacturacionTable.estadoId, estadosDocFacturacionTable.id)
      )
      .where(eq(ventasTable.sucursalId, sucursalId))

    return ventas
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

  async execute(sucursalId: SucursalIdType) {
    await this.validatePermissions(sucursalId)

    const ventas = await this.getVentas(sucursalId)

    return ventas
  }
}
