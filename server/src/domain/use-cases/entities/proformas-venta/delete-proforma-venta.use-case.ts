import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { proformasVentaTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq } from 'drizzle-orm'

export class DeleteProformaVenta {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.proformasVenta.deleteAny
  private readonly permissionRelated =
    permissionCodes.proformasVenta.deleteRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async deleteProformaVenta(
    numericIdDto: NumericIdDto,
    sucursalId: SucursalIdType
  ) {
    const results = await db
      .delete(proformasVentaTable)
      .where(
        and(
          eq(proformasVentaTable.id, numericIdDto.id),
          eq(proformasVentaTable.sucursalId, sucursalId)
        )
      )
      .returning({ id: proformasVentaTable.id })

    if (results.length < 1) {
      throw CustomError.badRequest(
        `No se pudo eliminar la proforma de venta con el id ${numericIdDto.id} (No encontrada)`
      )
    }

    const [proformaVenta] = results

    return proformaVenta
  }

  private async validatePermissions(sucursalId: SucursalIdType) {
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

    const isSameSucursal = validPermissions.some(
      (permission) => permission.sucursalId === sucursalId
    )

    if (!hasPermissionAny && !isSameSucursal) {
      throw CustomError.forbidden()
    }
  }

  async execute(numericIdDto: NumericIdDto, sucursalId: SucursalIdType) {
    await this.validatePermissions(sucursalId)

    const proformaVenta = await this.deleteProformaVenta(
      numericIdDto,
      sucursalId
    )

    return proformaVenta
  }
}
