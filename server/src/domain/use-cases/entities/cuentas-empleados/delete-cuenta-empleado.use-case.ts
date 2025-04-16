import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { cuentasEmpleadosTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { eq } from 'drizzle-orm'

export class DeleteCuentaEmpleado {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.cuentasEmpleados.deleteAny

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async deleteCuentaEmpleado(numericIdDto: NumericIdDto) {
    const cuentasEmpleados = await db
      .delete(cuentasEmpleadosTable)
      .where(eq(cuentasEmpleadosTable.id, numericIdDto.id))
      .returning({ id: cuentasEmpleadosTable.id })

    if (cuentasEmpleados.length < 1) {
      throw CustomError.badRequest(
        `No se pudo eliminar la cuenta del empleado, No fue encontrada`
      )
    }

    const [cuentaEmpleado] = cuentasEmpleados

    return cuentaEmpleado
  }

  private async canDeleteCuentaEmpleado(numericIdDto: NumericIdDto) {
    const cuentasEmpleados = await db
      .select({
        eliminable: cuentasEmpleadosTable.eliminable
      })
      .from(cuentasEmpleadosTable)
      .where(eq(cuentasEmpleadosTable.id, numericIdDto.id))

    if (cuentasEmpleados.length < 1) {
      throw CustomError.notFound(
        'No se pudo eliminar la cuenta del colaborador (no encontrado)'
      )
    }

    const [cuentaEmpleado] = cuentasEmpleados

    if (!cuentaEmpleado.eliminable) {
      throw CustomError.badRequest(
        'La cuenta de este colaborador no puede ser eliminado'
      )
    }
  }

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny]
    )

    const hasPermissionAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionAny
    )

    if (!hasPermissionAny) {
      throw CustomError.forbidden()
    }
  }

  async execute(numericIdDto: NumericIdDto) {
    await this.validatePermissions()
    await this.canDeleteCuentaEmpleado(numericIdDto)

    const cuentaEmpleado = await this.deleteCuentaEmpleado(numericIdDto)

    return cuentaEmpleado
  }
}
