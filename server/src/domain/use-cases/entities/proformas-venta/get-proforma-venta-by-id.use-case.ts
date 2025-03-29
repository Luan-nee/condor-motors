import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  clientesTable,
  empleadosTable,
  proformasVentaTable,
  sucursalesTable
} from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq } from 'drizzle-orm'

export class GetProformaVentaById {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.productos.getAny
  private readonly permissionRelated = permissionCodes.productos.getRelated
  private readonly selectFields = {
    id: proformasVentaTable.id,
    nombre: proformasVentaTable.nombre,
    total: proformasVentaTable.total,
    cliente: {
      id: clientesTable.id,
      nombre: clientesTable.denominacion,
      numeroDocumento: clientesTable.numeroDocumento
    },
    empleado: {
      id: empleadosTable.id,
      nombre: empleadosTable.nombre
    },
    sucursal: {
      id: sucursalesTable.id,
      nombre: sucursalesTable.nombre
    },
    detalles: proformasVentaTable.detalles,
    fechaCreacion: proformasVentaTable.fechaCreacion,
    fechaActualizacion: proformasVentaTable.fechaActualizacion
  }

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async getProformaVenta(
    numericIdDto: NumericIdDto,
    sucursalId: SucursalIdType
  ) {
    const proformasVenta = await db
      .select(this.selectFields)
      .from(proformasVentaTable)
      .innerJoin(
        empleadosTable,
        eq(proformasVentaTable.empleadoId, empleadosTable.id)
      )
      .innerJoin(
        sucursalesTable,
        eq(proformasVentaTable.sucursalId, sucursalesTable.id)
      )
      .leftJoin(
        clientesTable,
        eq(proformasVentaTable.clienteId, clientesTable.id)
      )
      .where(
        and(
          eq(proformasVentaTable.sucursalId, sucursalId),
          eq(proformasVentaTable.id, numericIdDto.id)
        )
      )

    if (proformasVenta.length < 1) {
      throw CustomError.notFound('No se encontró la proforma de venta')
    }

    const [proformaVenta] = proformasVenta

    return proformaVenta
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

    const proformasVenta = await this.getProformaVenta(numericIdDto, sucursalId)

    return proformasVenta
  }
}
