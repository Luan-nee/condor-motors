import { estadosTransferenciasInvCodes, permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  estadosTransferenciasInventarios,
  itemsTransferenciaInventarioTable,
  productosTable,
  sucursalesTable,
  transferenciasInventariosTable
} from '@/db/schema'
import type { CreateTransferenciaInvDto } from '@/domain/dtos/entities/transferencias-inventario/create-transferencia-inventario.dto'
import { eq, ilike, inArray } from 'drizzle-orm'

export class CreateTransferenciaInv {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.transferenciasInvs.createAny
  private readonly permissionRelated =
    permissionCodes.transferenciasInvs.createRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async createTransferenciaInv(
    createTransferenciaInvDto: CreateTransferenciaInvDto
  ) {
    const [estadoPedido] = await db
      .select({
        id: estadosTransferenciasInventarios.id
      })
      .from(estadosTransferenciasInventarios)
      .where(
        ilike(
          estadosTransferenciasInventarios.codigo,
          estadosTransferenciasInvCodes.pedido
        )
      )

    const sucursales = await db
      .select({ id: sucursalesTable.id })
      .from(sucursalesTable)
      .where(
        eq(sucursalesTable.id, createTransferenciaInvDto.sucursalDestinoId)
      )

    if (sucursales.length < 1) {
      throw CustomError.badRequest(
        'La sucursal de destino especificada no existe'
      )
    }

    const productoIds = createTransferenciaInvDto.items.map(
      (item) => item.productoId
    )

    const result = await db.transaction(async (tx) => {
      const productos = await tx
        .select({
          id: productosTable.id
        })
        .from(productosTable)
        .where(inArray(productosTable.id, productoIds))

      const productosMap = new Map(productos.map((p) => [p.id, p]))

      const itemsTransferencia = []

      for (const item of createTransferenciaInvDto.items) {
        const producto = productosMap.get(item.productoId)

        if (producto === undefined) {
          throw CustomError.badRequest(
            `El producto con el id ${item.productoId} no existe`
          )
        }

        itemsTransferencia.push({
          cantidad: item.cantidad,
          productoId: item.productoId
        })
      }

      const [transferenciaInventario] = await tx
        .insert(transferenciasInventariosTable)
        .values({
          estadoTransferenciaId: estadoPedido.id,
          sucursalDestinoId: createTransferenciaInvDto.sucursalDestinoId,
          modificable: true
        })
        .returning({ id: transferenciasInventariosTable.id })

      const itemsTransferenciInv = await tx
        .insert(itemsTransferenciaInventarioTable)
        .values(
          itemsTransferencia.map((item) => ({
            ...item,
            transferenciaInventarioId: transferenciaInventario.id
          }))
        )
        .returning({ id: itemsTransferenciaInventarioTable.id })

      return {
        id: transferenciaInventario.id,
        items: itemsTransferenciInv
      }
    })

    return result
  }

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny, this.permissionRelated]
    )

    let hasPermissionAny = false
    let hasPermissionRelated = false
    // let isSameSucursal = false

    for (const permission of validPermissions) {
      if (permission.codigoPermiso === this.permissionAny) {
        hasPermissionAny = true
      }
      if (permission.codigoPermiso === this.permissionRelated) {
        hasPermissionRelated = true
      }
      // if (permission.sucursalId === sucursalId) {
      //   isSameSucursal = true
      // }

      if (hasPermissionAny || hasPermissionRelated) {
        return
      }
    }

    throw CustomError.forbidden()
  }

  async execute(createTransferenciaInvDto: CreateTransferenciaInvDto) {
    await this.validatePermissions()

    const transferenciaInventario = await this.createTransferenciaInv(
      createTransferenciaInvDto
    )

    return transferenciaInventario
  }
}
