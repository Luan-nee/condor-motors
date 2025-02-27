import { db } from '@/db/connection'
import {
  cuentasEmpleadosTable,
  permisosTables,
  rolesPermisosTable
} from '@/db/schema'
import { and, eq, or } from 'drizzle-orm'

export class AccessControl {
  private static getConditionals(permissionCodes: string[]) {
    const conditionals = permissionCodes.map((permissionCode) =>
      eq(permisosTables.codigoPermiso, permissionCode)
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
        permisoId: permisosTables.id,
        codigoPermiso: permisosTables.codigoPermiso,
        nombrePermiso: permisosTables.nombrePermiso
      })
      .from(rolesPermisosTable)
      .innerJoin(
        permisosTables,
        eq(rolesPermisosTable.permisoId, permisosTables.id)
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
