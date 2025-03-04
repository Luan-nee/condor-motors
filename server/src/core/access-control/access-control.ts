import { db } from '@/db/connection'
import {
  cuentasEmpleadosTable,
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
    const empleados = await db
      .select({
        rolCuentaEmpleadoId: cuentasEmpleadosTable.rolCuentaEmpleadoId
      })
      .from(cuentasEmpleadosTable)
      .where(eq(cuentasEmpleadosTable.id, authPayload.id))

    if (empleados.length < 1) {
      return []
    }

    const [empleado] = empleados

    const permissionConditionals = this.getConditionals(permissionCodes)

    const permissions = await db
      .select({
        permisoId: permisosTable.id,
        codigoPermiso: permisosTable.codigoPermiso,
        nombrePermiso: permisosTable.nombrePermiso
      })
      .from(rolesPermisosTable)
      .innerJoin(
        permisosTable,
        eq(rolesPermisosTable.permisoId, permisosTable.id)
      )
      .where(
        and(
          eq(rolesPermisosTable.rolId, empleado.rolCuentaEmpleadoId),
          permissionConditionals
        )
      )

    return permissions
  }
}
