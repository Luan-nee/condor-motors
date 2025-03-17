import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  cuentasEmpleadosTable,
  empleadosTable,
  rolesCuentasEmpleadosTable
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
    usuario: cuentasEmpleadosTable.usuario,
    rolEmpleado: rolesCuentasEmpleadosTable.nombreRol
  }

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async getRelated(
    numericIdDto: NumericIdDto,
    sucursalId: SucursalIdType
  ) {
    return await db
      .select(this.selectFields)
      .from(cuentasEmpleadosTable)
      .innerJoin(
        rolesCuentasEmpleadosTable,
        eq(
          cuentasEmpleadosTable.rolCuentaEmpleadoId,
          rolesCuentasEmpleadosTable.id
        )
      )
      .innerJoin(
        empleadosTable,
        eq(cuentasEmpleadosTable.empleadoId, empleadosTable.id)
      )
      .where(
        and(
          eq(cuentasEmpleadosTable.id, numericIdDto.id),
          eq(empleadosTable.sucursalId, sucursalId)
        )
      )
  }

  private async getAny(numericIdDto: NumericIdDto) {
    return await db
      .select(this.selectFields)
      .from(cuentasEmpleadosTable)
      .innerJoin(
        rolesCuentasEmpleadosTable,
        eq(
          cuentasEmpleadosTable.rolCuentaEmpleadoId,
          rolesCuentasEmpleadosTable.id
        )
      )
      .where(eq(cuentasEmpleadosTable.id, numericIdDto.id))
  }

  private async getCuentaEmpleado(
    numericIdDto: NumericIdDto,
    hasPermissionAny: boolean,
    sucursalId: SucursalIdType
  ) {
    const empleados = hasPermissionAny
      ? await this.getAny(numericIdDto)
      : await this.getRelated(numericIdDto, sucursalId)

    if (empleados.length < 1) {
      throw CustomError.notFound(
        `No se encontró ninguna cuenta con el id ${numericIdDto.id}`
      )
    }

    const [empleado] = empleados

    return empleado
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

  async execute(numericIdDto: NumericIdDto) {
    const { hasPermissionAny, sucursalId } = await this.validatePermissions()

    const cuentaEmpleado = await this.getCuentaEmpleado(
      numericIdDto,
      hasPermissionAny,
      sucursalId
    )

    return cuentaEmpleado
  }
}
