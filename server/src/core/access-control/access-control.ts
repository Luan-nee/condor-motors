import { db } from '@/db/connection'
import {
  cuentasEmpleadosTable,
  empleadosTable,
  permisosTable,
  rolesPermisosTable
} from '@/db/schema'
import { and, eq, or } from 'drizzle-orm'

export class AccessControl {
  private static getConditionals(permissionCodes: string[]) {
    const conditionals = permissionCodes.map((permissionCode) =>
      eq(permisosTable.codigoPermiso, permissionCode)
    )

    return or(...conditionals)
  }

  static async verifyPermissions(
    authPayload: AuthPayload,
    permissionCodes: string[]
  ) {
    const permissionConditionals = this.getConditionals(permissionCodes)

    const permissions = await db
      .select({
        codigoPermiso: permisosTable.codigoPermiso,
        sucursalId: empleadosTable.sucursalId
      })
      .from(rolesPermisosTable)
      .innerJoin(
        permisosTable,
        eq(permisosTable.id, rolesPermisosTable.permisoId)
      )
      .innerJoin(
        cuentasEmpleadosTable,
        eq(cuentasEmpleadosTable.rolCuentaEmpleadoId, rolesPermisosTable.rolId)
      )
      .innerJoin(
        empleadosTable,
        eq(empleadosTable.id, cuentasEmpleadosTable.empleadoId)
      )
      .where(
        and(
          eq(cuentasEmpleadosTable.id, authPayload.id),
          permissionConditionals
        )
      )

    return permissions
  }
}
