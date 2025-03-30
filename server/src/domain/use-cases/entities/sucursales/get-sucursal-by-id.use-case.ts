import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { empleadosTable, sucursalesTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { count, eq } from 'drizzle-orm'

export class GetSucursalById {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.sucursales.getAny
  private readonly permissionRelated = permissionCodes.sucursales.getRelated
  private readonly selectFields = {
    id: sucursalesTable.id,
    nombre: sucursalesTable.nombre,
    direccion: sucursalesTable.direccion,
    sucursalCentral: sucursalesTable.sucursalCentral,
    serieFactura: sucursalesTable.serieFactura,
    numeroFacturaInicial: sucursalesTable.numeroFacturaInicial,
    serieBoleta: sucursalesTable.serieBoleta,
    numeroBoletaInicial: sucursalesTable.numeroBoletaInicial,
    codigoEstablecimiento: sucursalesTable.codigoEstablecimiento,
    tieneNotificaciones: sucursalesTable.tieneNotificaciones,
    fechaCreacion: sucursalesTable.fechaCreacion,
    fechaActualizacion: sucursalesTable.fechaActualizacion,
    totalEmpleados: count(empleadosTable.id)
  }

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async getSucursalById(numericIdDto: NumericIdDto) {
    const sucursales = await db
      .select(this.selectFields)
      .from(sucursalesTable)
      .leftJoin(
        empleadosTable,
        eq(sucursalesTable.id, empleadosTable.sucursalId)
      )
      .where(eq(sucursalesTable.id, numericIdDto.id))
      .groupBy(sucursalesTable.id)

    if (sucursales.length < 1) {
      throw CustomError.badRequest(
        `No se encontró ninguna sucursal con el id '${numericIdDto.id}'`
      )
    }

    const [sucursal] = sucursales

    return sucursal
  }

  private async validatePermissions(numericIdDto: NumericIdDto) {
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
      if (permission.sucursalId === numericIdDto.id) {
        isSameSucursal = true
      }

      if (hasPermissionAny || (hasPermissionRelated && isSameSucursal)) {
        return
      }
    }

    throw CustomError.forbidden()
  }

  async execute(numericIdDto: NumericIdDto) {
    await this.validatePermissions(numericIdDto)

    const sucursal = await this.getSucursalById(numericIdDto)

    return sucursal
  }
}
