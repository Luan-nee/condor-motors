import { db } from '@/db/connection'
import {
  cuentasEmpleadosTable,
  empleadosTable,
  permisosTable,
  rolesPermisosTable
} from '@/db/schema'
import { and, eq, inArray } from 'drizzle-orm'

export class AccessControl {
  static async verifyPermissions(
    authPayload: AuthPayload,
    permissionCodes: string[]
  ) {
    const permissions = await db
      .select({
        codigoPermiso: permisosTable.codigo,
        sucursalId: empleadosTable.sucursalId
      })
      .from(rolesPermisosTable)
      .innerJoin(
        permisosTable,
        eq(permisosTable.id, rolesPermisosTable.permisoId)
      )
      .innerJoin(
        cuentasEmpleadosTable,
        eq(cuentasEmpleadosTable.rolId, rolesPermisosTable.rolId)
      )
      .innerJoin(
        empleadosTable,
        eq(empleadosTable.id, cuentasEmpleadosTable.empleadoId)
      )
      .where(
        and(
          eq(cuentasEmpleadosTable.id, authPayload.id),
          inArray(permisosTable.codigo, permissionCodes)
        )
      )

    return permissions
  }
}
