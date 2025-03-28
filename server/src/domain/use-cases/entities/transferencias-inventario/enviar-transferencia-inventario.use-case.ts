import { estadosTransferenciasInvCodes, permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  detallesProductoTable,
  estadosTransferenciasInventarios,
  itemsTransferenciaInventarioTable,
  productosTable,
  sucursalesTable,
  transferenciasInventariosTable
} from '@/db/schema'
import type { EnviarTransferenciaInvDto } from '@/domain/dtos/entities/transferencias-inventario/enviar-transferencia-inventario.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq, ilike, inArray } from 'drizzle-orm'

export class EnviarTransferenciaInventario {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.transferenciasInvs.sendAny
  private readonly permissionRelated =
    permissionCodes.transferenciasInvs.sendRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async enviarTransferenciaInv(
    enviarTransferenciaInvDto: EnviarTransferenciaInvDto
  ) {
    const now = new Date()

    const [estadoEnviado] = await db
      .select({
        id: estadosTransferenciasInventarios.id
      })
      .from(estadosTransferenciasInventarios)
      .where(
        ilike(
          estadosTransferenciasInventarios.codigo,
          estadosTransferenciasInvCodes.enviado
        )
      )

    const itemsTransferencia = await db
      .select({
        id: itemsTransferenciaInventarioTable.id,
        productoId: itemsTransferenciaInventarioTable.productoId,
        cantidad: itemsTransferenciaInventarioTable.cantidad
      })
      .from(itemsTransferenciaInventarioTable)
      .where(
        eq(
          itemsTransferenciaInventarioTable.transferenciaInventarioId,
          enviarTransferenciaInvDto.transferenciaInvId
        )
      )

    if (itemsTransferencia.length < 1) {
      throw CustomError.badRequest(
        'La transferencia de inventario no tiene ningún producto para ser transferido'
      )
    }

    const productoIds = itemsTransferencia.map((item) => item.productoId)

    const [result] = await db.transaction(async (tx) => {
      const productos = await tx
        .select({
          id: detallesProductoTable.id,
          nombre: productosTable.nombre,
          stock: detallesProductoTable.stock,
          productoId: detallesProductoTable.productoId
        })
        .from(detallesProductoTable)
        .innerJoin(
          productosTable,
          eq(productosTable.id, detallesProductoTable.productoId)
        )
        .where(
          and(
            eq(
              detallesProductoTable.sucursalId,
              enviarTransferenciaInvDto.sucursalOrigenId
            ),
            inArray(detallesProductoTable.productoId, productoIds)
          )
        )

      const productosMap = new Map(productos.map((p) => [p.productoId, p]))

      for (const itemTransferencia of itemsTransferencia) {
        const producto = productosMap.get(itemTransferencia.productoId)

        if (producto === undefined) {
          throw CustomError.badRequest(
            `El producto con id ${itemTransferencia.productoId} no existe en la sucursal de origen especificada`
          )
        }

        if (producto.stock < itemTransferencia.cantidad) {
          throw CustomError.badRequest(
            `El producto ${producto.nombre} de la sucursal de origen no tiene el stock suficiente para abastecer este pedido`
          )
        }

        await tx
          .update(detallesProductoTable)
          .set({ stock: producto.stock - itemTransferencia.cantidad })
          .where(
            and(
              eq(
                detallesProductoTable.sucursalId,
                enviarTransferenciaInvDto.sucursalOrigenId
              ),
              eq(detallesProductoTable.productoId, itemTransferencia.productoId)
            )
          )
      }

      const transferenciasInvs = await tx
        .update(transferenciasInventariosTable)
        .set({
          modificable: false,
          estadoTransferenciaId: estadoEnviado.id,
          sucursalOrigenId: enviarTransferenciaInvDto.sucursalOrigenId,
          salidaOrigen: now,
          fechaActualizacion: now
        })
        .where(
          eq(
            transferenciasInventariosTable.id,
            enviarTransferenciaInvDto.transferenciaInvId
          )
        )
        .returning({
          id: transferenciasInventariosTable.id,
          sucursalOrigenId: transferenciasInventariosTable.sucursalOrigenId,
          sucursalDestinoId: transferenciasInventariosTable.sucursalDestinoId
        })

      if (transferenciasInvs.length < 1) {
        throw CustomError.internalServer(
          'Ha ocurrido un error al intentar realizar la transferencia de inventario'
        )
      }

      return transferenciasInvs
    })

    return result
  }

  private async validateRelated(
    enviarTransferenciaInvDto: EnviarTransferenciaInvDto,
    sucursalId: SucursalIdType,
    hasPermissionAny: boolean
  ) {
    const sucursales = await db
      .select({ id: sucursalesTable.id })
      .from(sucursalesTable)
      .where(eq(sucursalesTable.id, enviarTransferenciaInvDto.sucursalOrigenId))

    if (sucursales.length < 1) {
      throw CustomError.badRequest(
        'La sucursal de origen especificada no existe'
      )
    }

    const transferenciasInventario = await db
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
      .where(
        eq(
          transferenciasInventariosTable.id,
          enviarTransferenciaInvDto.transferenciaInvId
        )
      )

    if (transferenciasInventario.length < 1) {
      throw CustomError.badRequest(
        'La transferencia de inventario que intentó atender no existe'
      )
    }

    const [transferenciaInventario] = transferenciasInventario

    if (
      transferenciaInventario.codigoEstado !==
        estadosTransferenciasInvCodes.pedido ||
      !transferenciaInventario.modificable
    ) {
      throw CustomError.badRequest(
        'La transferencia de inventario que intentó atender ya ha sido atendida o no es modificable'
      )
    }

    if (
      transferenciaInventario.sucursalDestinoId ===
      enviarTransferenciaInvDto.sucursalOrigenId
    ) {
      throw CustomError.badRequest(
        'La sucursal de origen y de destino no puede ser la misma'
      )
    }

    if (
      sucursalId !== enviarTransferenciaInvDto.sucursalOrigenId &&
      !hasPermissionAny
    ) {
      throw CustomError.forbidden()
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

  async execute(enviarTransferenciaInvDto: EnviarTransferenciaInvDto) {
    const { hasPermissionAny, sucursalId } = await this.validatePermissions()

    await this.validateRelated(
      enviarTransferenciaInvDto,
      sucursalId,
      hasPermissionAny
    )

    const result = await this.enviarTransferenciaInv(enviarTransferenciaInvDto)

    return result
  }
}
