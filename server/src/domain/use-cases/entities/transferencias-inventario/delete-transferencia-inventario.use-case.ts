import { estadosTransferenciasInvCodes, permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  estadosTransferenciasInventarios,
  transferenciasInventariosTable
} from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { SucursalIdType } from '@/types/schemas'
import { eq } from 'drizzle-orm'

export class DeleteTransferenciaInventario {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.transferenciasInvs.deleteAny
  private readonly permissionRelated =
    permissionCodes.transferenciasInvs.deleteRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async deleteTransferenciInv(
    numericIdDto: NumericIdDto,
    sucursalId: SucursalIdType,
    hasPermissionAny: boolean
  ) {
    const results = await db
      .select({
        id: transferenciasInventariosTable.id,
        modificable: transferenciasInventariosTable.modificable,
        sucursalDestinoId: transferenciasInventariosTable.sucursalDestinoId,
        codigoEstado: estadosTransferenciasInventarios.codigo
      })
      .from(transferenciasInventariosTable)
      .innerJoin(
        estadosTransferenciasInventarios,
        eq(
          transferenciasInventariosTable.estadoTransferenciaId,
          estadosTransferenciasInventarios.id
        )
      )
      .where(eq(transferenciasInventariosTable.id, numericIdDto.id))

    if (results.length < 1) {
      if (!hasPermissionAny) {
        throw CustomError.forbidden()
      }

      throw CustomError.badRequest(
        'La transferencia de inventario que intentó eliminar no existe'
      )
    }

    const [result] = results

    if (result.sucursalDestinoId !== sucursalId && !hasPermissionAny) {
      throw CustomError.forbidden()
    }

    if (result.codigoEstado !== estadosTransferenciasInvCodes.pedido) {
      throw CustomError.badRequest(
        'La transferencia de inventario que intentó eliminar no puede ser eliminada porque ya ha sido procesada'
      )
    }

    const transferenciasInv = await db
      .delete(transferenciasInventariosTable)
      .where(eq(transferenciasInventariosTable.id, numericIdDto.id))
      .returning({ id: transferenciasInventariosTable.id })

    if (transferenciasInv.length < 1) {
      throw CustomError.badRequest(
        `No se pudo eliminar la transferencia de inventario (No encontrada)`
      )
    }

    const [transferenciaInv] = transferenciasInv

    return transferenciaInv
  }

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny, this.permissionRelated]
    )

    let hasPermissionAny = false
    let hasPermissionRelated = false

    for (const permission of validPermissions) {
      if (permission.codigoPermiso === this.permissionAny) {
        hasPermissionAny = true
      }
      if (permission.codigoPermiso === this.permissionRelated) {
        hasPermissionRelated = true
      }

      if (hasPermissionAny || hasPermissionRelated) {
        return { hasPermissionAny, sucursalId: permission.sucursalId }
      }
    }

    throw CustomError.forbidden()
  }

  async execute(numericIdDto: NumericIdDto) {
    const { hasPermissionAny, sucursalId } = await this.validatePermissions()

    const result = await this.deleteTransferenciInv(
      numericIdDto,
      sucursalId,
      hasPermissionAny
    )

    return result
  }
}
