import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  cuentasEmpleadosTable,
  empleadosTable,
  sucursalesTable
} from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { and, eq } from 'drizzle-orm'

export class GetSucursalById {
  private readonly authPayload: AuthPayload
  private readonly permissionGetAny = permissionCodes.sucursales.getAny
  private readonly permissionGetRelated = permissionCodes.sucursales.getRelated
  private readonly selectFields = {
    id: sucursalesTable.id,
    nombre: sucursalesTable.nombre,
    direccion: sucursalesTable.direccion,
    sucursalCentral: sucursalesTable.sucursalCentral,
    serieFacturaSucursal: sucursalesTable.serieFactura,
    serieBoletaSucursal: sucursalesTable.serieBoleta,
    codigoEstablecimiento: sucursalesTable.codigoEstablecimiento,
    tieneNotificaciones: sucursalesTable.tieneNotificaciones,
    fechaCreacion: sucursalesTable.fechaCreacion,
    fechaActualizacion: sucursalesTable.fechaActualizacion
  }

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async getRelatedSucursal(numericIdDto: NumericIdDto) {
    return await db
      .select(this.selectFields)
      .from(sucursalesTable)
      .innerJoin(
        empleadosTable,
        eq(empleadosTable.sucursalId, sucursalesTable.id)
      )
      .innerJoin(
        cuentasEmpleadosTable,
        eq(cuentasEmpleadosTable.empleadoId, empleadosTable.id)
      )
      .where(
        and(
          eq(sucursalesTable.id, numericIdDto.id),
          eq(cuentasEmpleadosTable.id, this.authPayload.id)
        )
      )
  }

  private async getAnySucursal(numericIdDto: NumericIdDto) {
    return await db
      .select(this.selectFields)
      .from(sucursalesTable)
      .where(eq(sucursalesTable.id, numericIdDto.id))
  }

  private async getSucursalById(
    numericIdDto: NumericIdDto,
    hasPermissionGetAny: boolean
  ) {
    const sucursales = hasPermissionGetAny
      ? await this.getAnySucursal(numericIdDto)
      : await this.getRelatedSucursal(numericIdDto)

    if (sucursales.length < 1) {
      if (!hasPermissionGetAny) {
        throw CustomError.forbidden()
      }

      throw CustomError.badRequest(
        `No se encontró ninguna sucursal con el id '${numericIdDto.id}'`
      )
    }

    const [sucursal] = sucursales

    return sucursal
  }

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionGetAny, this.permissionGetRelated]
    )

    const hasPermissionGetAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionGetAny
    )

    if (
      !hasPermissionGetAny &&
      !validPermissions.some(
        (permission) => permission.codigoPermiso === this.permissionGetRelated
      )
    ) {
      throw CustomError.forbidden()
    }

    return hasPermissionGetAny
  }

  async execute(numericIdDto: NumericIdDto) {
    const hasPermissionGetAny = await this.validatePermissions()

    const sucursal = await this.getSucursalById(
      numericIdDto,
      hasPermissionGetAny
    )

    return sucursal
  }
}
