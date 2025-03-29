import { estadosTransferenciasInvCodes, permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  estadosTransferenciasInventarios,
  itemsTransferenciaInventarioTable,
  productosTable,
  transferenciasInventariosTable
} from '@/db/schema'
import type { AddItemTransferenciaInvDto } from '@/domain/dtos/entities/transferencias-inventario/add-item-transferencia-inventario.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { SucursalIdType } from '@/types/schemas'
import { eq, inArray } from 'drizzle-orm'

export class AddItemTransferenciaInv {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.transferenciasInvs.createAny
  private readonly permissionRelated =
    permissionCodes.transferenciasInvs.createRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async addItemTransferenciaInv(
    numericIdDto: NumericIdDto,
    addItemTransferenciaInvDto: AddItemTransferenciaInvDto,
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

    const productoIds = addItemTransferenciaInvDto.items.map(
      (item) => item.productoId
    )

    const transferenciaInv = await db.transaction(async (tx) => {
      const currentItems = await tx
        .select({
          id: itemsTransferenciaInventarioTable.id,
          productoId: itemsTransferenciaInventarioTable.productoId
        })
        .from(itemsTransferenciaInventarioTable)
        .where(
          eq(
            itemsTransferenciaInventarioTable.transferenciaInventarioId,
            numericIdDto.id
          )
        )

      this.checkDuplicatedProducts(
        currentItems.map((item) => item.productoId),
        addItemTransferenciaInvDto
      )

      const productos = await tx
        .select({
          id: productosTable.id
        })
        .from(productosTable)
        .where(inArray(productosTable.id, productoIds))

      const productosMap = new Map(productos.map((p) => [p.id, p]))
      const itemsTransferencia = []

      for (const item of addItemTransferenciaInvDto.items) {
        const producto = productosMap.get(item.productoId)

        if (producto === undefined) {
          throw CustomError.badRequest(
            `El producto con el id ${item.productoId} no existe`
          )
        }

        itemsTransferencia.push({
          cantidad: item.cantidad,
          productoId: item.productoId,
          transferenciaInventarioId: numericIdDto.id
        })
      }

      const itemsTransferenciInv = await tx
        .insert(itemsTransferenciaInventarioTable)
        .values(itemsTransferencia)
        .returning({ id: itemsTransferenciaInventarioTable.id })

      return {
        id: numericIdDto.id,
        items: itemsTransferenciInv
      }
    })

    return transferenciaInv
  }

  private checkDuplicatedProducts(
    currentItems: number[],
    addItemTransferenciaInvDto: AddItemTransferenciaInvDto
  ) {
    const productoIds = new Set<number>(currentItems)
    const duplicateProductIds = new Set<number>()

    for (const { productoId } of addItemTransferenciaInvDto.items) {
      if (productoIds.has(productoId)) {
        duplicateProductIds.add(productoId)
      } else {
        productoIds.add(productoId)
      }
    }

    if (duplicateProductIds.size > 0) {
      throw CustomError.badRequest(
        `Existen productos duplicados en los items: ${[...duplicateProductIds].join(', ')}`
      )
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

  async execute(
    numericIdDto: NumericIdDto,
    addItemTransferenciaInvDto: AddItemTransferenciaInvDto
  ) {
    const { hasPermissionAny, sucursalId } = await this.validatePermissions()

    const transferenciaInventario = await this.addItemTransferenciaInv(
      numericIdDto,
      addItemTransferenciaInvDto,
      sucursalId,
      hasPermissionAny
    )

    return transferenciaInventario
  }
}
