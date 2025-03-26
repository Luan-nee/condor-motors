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
import type { SucursalIdType } from '@/types/schemas'
import { eq } from 'drizzle-orm'

export class GetCuentasEmpleados {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.cuentasEmpleados.getAny
  private readonly permissionRelated =
    permissionCodes.cuentasEmpleados.getRelated
  private readonly selectFields = {
    id: cuentasEmpleadosTable.id,
    usuario: cuentasEmpleadosTable.usuario,
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

  private async getRelated(sucursalId: SucursalIdType) {
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
      .where(eq(empleadosTable.sucursalId, sucursalId))
  }

  private async getAny() {
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
  }

  private async getCuentaEmpleado(
    hasPermissionAny: boolean,
    sucursalId: SucursalIdType
  ) {
    const empleados = hasPermissionAny
      ? await this.getAny()
      : await this.getRelated(sucursalId)

    return empleados
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

  async execute() {
    const { hasPermissionAny, sucursalId } = await this.validatePermissions()

    const cuentaEmpleado = await this.getCuentaEmpleado(
      hasPermissionAny,
      sucursalId
    )

    return cuentaEmpleado
  }
}
