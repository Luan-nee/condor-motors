import { db } from '@/db/connection'
import {
  cuentasEmpleadosTable,
  permisosTables,
  rolesPermisosTable
} from '@/db/schema'
import type { NumericIdDto } from '@domain/dtos/query-params/numeric-id.dto'
import { and, eq } from 'drizzle-orm'

export class AccessControl {
  private static async verify(
    numericIdDto: NumericIdDto,
    permissionCode: string
  ) {
    const empleados = await db
      .select({
        rolCuentaEmpleadoId: cuentasEmpleadosTable.rolCuentaEmpleadoId
      })
      .from(cuentasEmpleadosTable)
      .where(eq(cuentasEmpleadosTable.id, numericIdDto.id))

    if (empleados.length < 1) {
      return false
    }

    const [empleado] = empleados

    const permisos = await db
      .select()
      .from(rolesPermisosTable)
      .innerJoin(
        permisosTables,
        eq(rolesPermisosTable.permisoId, permisosTables.id)
      )
      .where(
        and(
          eq(rolesPermisosTable.rolId, empleado.rolCuentaEmpleadoId),
          eq(permisosTables.codigoPermiso, permissionCode)
        )
      )

    return permisos.length > 1
  }

  static async hasPermission(
    numericIdDto: NumericIdDto,
    permissionCode: string
  ) {
    const hasPermission = await this.verify(numericIdDto, permissionCode)

    return hasPermission
  }
}
