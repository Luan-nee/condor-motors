import { estadosTransferenciasInvCodes, permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  estadosTransferenciasInventarios,
  itemsTransferenciaInventarioTable,
  transferenciasInventariosTable
} from '@/db/schema'
import type { DoubleNumericIdDto } from '@/domain/dtos/query-params/double-numeric.-id.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq } from 'drizzle-orm'

export class RemoveItemTransferenciaInv {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.transferenciasInvs.deleteAny
  private readonly permissionRelated =
    permissionCodes.transferenciasInvs.deleteRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async removeItemTransferenciaInv(
    doubleNumericIdDto: DoubleNumericIdDto,
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
      .where(eq(transferenciasInventariosTable.id, doubleNumericIdDto.id))

    if (results.length < 1) {
      if (!hasPermissionAny) {
        throw CustomError.forbidden()
      }

      throw CustomError.badRequest(
        'La transferencia de inventario que intentó modificar no existe'
      )
    }

    const [result] = results

    if (result.sucursalDestinoId !== sucursalId && !hasPermissionAny) {
      throw CustomError.forbidden()
    }

    if (result.codigoEstado !== estadosTransferenciasInvCodes.pedido) {
      throw CustomError.badRequest(
        'La transferencia de inventario que intentó modificar no puede ser modificada porque ya ha sido procesada'
      )
    }

    const itemsTransferenciaInv = await db
      .delete(itemsTransferenciaInventarioTable)
      .where(
        and(
          eq(
            itemsTransferenciaInventarioTable.transferenciaInventarioId,
            doubleNumericIdDto.id
          ),
          eq(itemsTransferenciaInventarioTable.id, doubleNumericIdDto.secondId)
        )
      )
      .returning({ id: itemsTransferenciaInventarioTable.id })

    if (itemsTransferenciaInv.length < 1) {
      throw CustomError.badRequest(
        'No se ha podido eliminar el item especificado (no encontrado)'
      )
    }

    return {
      id: doubleNumericIdDto.id,
      items: itemsTransferenciaInv
    }
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

  async execute(doubleNumericIdDto: DoubleNumericIdDto) {
    const { hasPermissionAny, sucursalId } = await this.validatePermissions()

    const transferenciaInventario = await this.removeItemTransferenciaInv(
      doubleNumericIdDto,
      sucursalId,
      hasPermissionAny
    )

    return transferenciaInventario
  }
}
