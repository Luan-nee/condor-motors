import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  cuentasEmpleadosTable,
  empleadosTable,
  rolesTable,
  sucursalesTable
} from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq } from 'drizzle-orm'

export class GetCuentaEmpleado {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.cuentasEmpleados.getAny
  private readonly permissionRelated =
    permissionCodes.cuentasEmpleados.getRelated
  private readonly selectFields = {
    id: cuentasEmpleadosTable.id,
    usuario: cuentasEmpleadosTable.usuario,
    rolCuentaEmpleadoId: cuentasEmpleadosTable.rolId,
    rolEmpleado: rolesTable.nombre,
    empleado: {
      id: empleadosTable.id,
      nombre: empleadosTable.nombre
    },
    sucursal: {
      nombre: sucursalesTable.nombre
    }
  }

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async getRelated(
    numericIdDto: NumericIdDto,
    searchBy: 'cuenta' | 'empleado',
    sucursalId: SucursalIdType
  ) {
    const filterCondition = searchBy === 'cuenta'
      ? eq(cuentasEmpleadosTable.id, numericIdDto.id)
      : eq(cuentasEmpleadosTable.empleadoId, numericIdDto.id)

    return await db
      .select(this.selectFields)
      .from(cuentasEmpleadosTable)
      .innerJoin(rolesTable, eq(cuentasEmpleadosTable.rolId, rolesTable.id))
      .innerJoin(
        empleadosTable,
        eq(cuentasEmpleadosTable.empleadoId, empleadosTable.id)
      )
      .innerJoin(
        sucursalesTable,
        eq(empleadosTable.sucursalId, sucursalesTable.id)
      )
      .where(
        and(
          filterCondition,
          eq(empleadosTable.sucursalId, sucursalId)
        )
      )
  }

  private async getAny(numericIdDto: NumericIdDto, searchBy: 'cuenta' | 'empleado') {
    const filterCondition = searchBy === 'cuenta'
      ? eq(cuentasEmpleadosTable.id, numericIdDto.id)
      : eq(cuentasEmpleadosTable.empleadoId, numericIdDto.id)

    return await db
      .select(this.selectFields)
      .from(cuentasEmpleadosTable)
      .innerJoin(rolesTable, eq(cuentasEmpleadosTable.rolId, rolesTable.id))
      .innerJoin(
        empleadosTable,
        eq(cuentasEmpleadosTable.empleadoId, empleadosTable.id)
      )
      .innerJoin(
        sucursalesTable,
        eq(empleadosTable.sucursalId, sucursalesTable.id)
      )
      .where(filterCondition)
  }

  private async getCuentaEmpleado(
    numericIdDto: NumericIdDto,
    searchBy: 'cuenta' | 'empleado',
    hasPermissionAny: boolean,
    sucursalId: SucursalIdType
  ) {
    const records = hasPermissionAny
      ? await this.getAny(numericIdDto, searchBy)
      : await this.getRelated(numericIdDto, searchBy, sucursalId)

    if (records.length < 1) {
      const resourceName = searchBy === 'cuenta' ? 'cuenta' : 'empleado'
      throw CustomError.notFound(
        `No se encontró ninguna cuenta asociada para el ${resourceName} con id ${numericIdDto.id}`
      )
    }

    const [record] = records

    return record
  }

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny, this.permissionRelated]
    )

    const hasPermissionAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionAny
    )

    if (
      !hasPermissionAny &&
      !validPermissions.some(
        (permission) => permission.codigoPermiso === this.permissionRelated
      )
    ) {
      throw CustomError.forbidden()
    }

    const [permission] = validPermissions

    return { hasPermissionAny, sucursalId: permission.sucursalId }
  }

  async execute(numericIdDto: NumericIdDto, searchBy: 'cuenta' | 'empleado' = 'cuenta') {
    const { hasPermissionAny, sucursalId } = await this.validatePermissions()

    const cuentaEmpleado = await this.getCuentaEmpleado(
      numericIdDto,
      searchBy,
      hasPermissionAny,
      sucursalId
    )

    return cuentaEmpleado
  }
}
