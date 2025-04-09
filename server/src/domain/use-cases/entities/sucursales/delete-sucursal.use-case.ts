import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { sucursalesTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { eq } from 'drizzle-orm'

export class DeleteSucursal {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.sucursales.deleteAny

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async deleteSucursal(numericIdDto: NumericIdDto) {
    const sucursales = await db
      .delete(sucursalesTable)
      .where(eq(sucursalesTable.id, numericIdDto.id))
      .returning({ id: sucursalesTable.id })

    if (sucursales.length <= 0) {
      throw CustomError.badRequest(
        `No se pudo eliminar la sucursal con el id '${numericIdDto.id}' (No encontrada)`
      )
    }

    const [sucursal] = sucursales

    return sucursal
  }

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny]
    )

    let hasPermissionAny = false

    for (const permission of validPermissions) {
      if (permission.codigoPermiso === this.permissionAny) {
        hasPermissionAny = true
      }

      if (hasPermissionAny) {
        return
      }
    }

    throw CustomError.forbidden()
  }

  async execute(numericIdDto: NumericIdDto) {
    await this.validatePermissions()

    const sucursal = await this.deleteSucursal(numericIdDto)

    return sucursal
  }
}
