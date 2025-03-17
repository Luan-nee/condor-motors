import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { rolesCuentasEmpleadosTable } from '@/db/schema'
import { asc } from 'drizzle-orm'

export class GetRolesCuentas {
  private readonly authPayload: AuthPayload
  private readonly permissionGetAny =
    permissionCodes.rolesCuentasEmpleados.getAny
  private readonly selectFields = {
    id: rolesCuentasEmpleadosTable.id,
    nombreRol: rolesCuentasEmpleadosTable.nombreRol,
    codigo: rolesCuentasEmpleadosTable.codigo
  }

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionGetAny]
    )

    const hasPermissionGetAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionGetAny
    )

    if (!hasPermissionGetAny) {
      throw CustomError.forbidden()
    }
  }

  async execute() {
    await this.validatePermissions()

    const rolesCuentas = await db
      .select(this.selectFields)
      .from(rolesCuentasEmpleadosTable)
      .orderBy(asc(rolesCuentasEmpleadosTable.nombreRol))

    return rolesCuentas
  }
}
