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
import { SucursalEntityMapper } from '@/domain/mappers/sucursal-entity.mapper'
import { eq, sql } from 'drizzle-orm'

export class GetSucursalById {
  private readonly authPayload: AuthPayload
  private readonly permissionGetAny = permissionCodes.sucursales.getAny
  private readonly permissionGetRelated = permissionCodes.sucursales.getRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private readonly selectFields = {
    id: sucursalesTable.id,
    nombre: sucursalesTable.nombre,
    direccion: sucursalesTable.direccion,
    sucursalCentral: sucursalesTable.sucursalCentral,
    fechaCreacion: sucursalesTable.fechaCreacion,
    fechaActualizacion: sucursalesTable.fechaActualizacion
  }

  private getQuery(hasPermissionGetAny: boolean) {
    if (hasPermissionGetAny) {
      return db
        .select(this.selectFields)
        .from(sucursalesTable)
        .where(eq(sucursalesTable.id, sql.placeholder('sucursal_id')))
        .prepare('get_sucursal_by_id')
    }

    return db
      .select(this.selectFields)
      .from(sucursalesTable)
      .innerJoin(
        empleadosTable,
        eq(empleadosTable.sucursalId, sucursalesTable.id)
      )
      .innerJoin(
        cuentasEmpleadosTable,
        eq(cuentasEmpleadosTable.id, this.authPayload.id)
      )
      .where(eq(sucursalesTable.id, sql.placeholder('sucursal_id')))
      .prepare('get_sucursal_by_id')
  }

  private async getSucursalById(
    numericIdDto: NumericIdDto,
    hasPermissionGetAny: boolean
  ) {
    const query = this.getQuery(hasPermissionGetAny)

    const sucursales = await query.execute({ sucursal_id: numericIdDto.id })

    if (sucursales.length <= 0) {
      if (!hasPermissionGetAny) {
        throw CustomError.forbidden(
          'No tienes los suficientes permisos para realizar esta acción'
        )
      }

      throw CustomError.badRequest(
        `No se encontró ninguna sucursal con el id '${numericIdDto.id}'`
      )
    }

    const [sucursal] = sucursales

    const mappedSucursal =
      SucursalEntityMapper.sucursalEntityFromObject(sucursal)

    return mappedSucursal
  }

  async execute(numericIdDto: NumericIdDto) {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionGetAny, this.permissionGetRelated]
    )

    if (
      !validPermissions.some(
        (permission) => permission.codigoPermiso === this.permissionGetAny
      ) &&
      !validPermissions.some(
        (permission) => permission.codigoPermiso === this.permissionGetRelated
      )
    ) {
      throw CustomError.forbidden(
        'No tienes los suficientes permisos para realizar esta acción'
      )
    }

    const hasPermissionGetAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionGetAny
    )

    const sucursal = await this.getSucursalById(
      numericIdDto,
      hasPermissionGetAny
    )

    return sucursal
  }
}
