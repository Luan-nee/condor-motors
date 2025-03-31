import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  detallesProductoTable,
  entradasInventariosTable,
  productosTable
} from '@/db/schema'
import type { EntradaInventarioDto } from '@/domain/dtos/entities/inventarios/entradas.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq } from 'drizzle-orm'

export class EntradaInventario {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.inventarios.addAny
  private readonly permissionRelated = permissionCodes.inventarios.addRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async entradaInventario(
    entradaInventarioDto: EntradaInventarioDto,
    sucursalId: SucursalIdType
  ) {
    const now = new Date()

    const insertedResult = await db.transaction(async (tx) => {
      const detallesProductos = await tx
        .select({
          currentStock: detallesProductoTable.stock,
          stockMinimo: productosTable.stockMinimo
        })
        .from(detallesProductoTable)
        .innerJoin(
          productosTable,
          eq(detallesProductoTable.productoId, productosTable.id)
        )
        .where(
          and(
            eq(detallesProductoTable.sucursalId, sucursalId),
            eq(
              detallesProductoTable.productoId,
              entradaInventarioDto.productoId
            )
          )
        )

      if (detallesProductos.length < 1) {
        throw CustomError.badRequest(
          'El producto especificado no se encontró en la sucursal especificada'
        )
      }

      const [detallesProducto] = detallesProductos

      const newStock =
        detallesProducto.currentStock + entradaInventarioDto.cantidad
      const stockBajo =
        detallesProducto.stockMinimo != null &&
        newStock < detallesProducto.stockMinimo

      const [entradaInventario] = await tx
        .insert(entradasInventariosTable)
        .values({
          cantidad: entradaInventarioDto.cantidad,
          productoId: entradaInventarioDto.productoId,
          sucursalId,
          fechaCreacion: now,
          fechaActualizacion: now
        })
        .returning({ id: entradasInventariosTable.id })

      const updatedDetallesProducto = await tx
        .update(detallesProductoTable)
        .set({
          stock: newStock,
          stockBajo,
          fechaActualizacion: now
        })
        .where(
          and(
            eq(detallesProductoTable.sucursalId, sucursalId),
            eq(
              detallesProductoTable.productoId,
              entradaInventarioDto.productoId
            )
          )
        )
        .returning()

      if (updatedDetallesProducto.length < 1) {
        throw CustomError.internalServer(
          'Ha ocurrido un error al intentar registar la entrada de inventario'
        )
      }

      return entradaInventario
    })

    return insertedResult
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

  async execute(
    entradaInventarioDto: EntradaInventarioDto,
    sucursalId: SucursalIdType
  ) {
    await this.validatePermissions(sucursalId)

    const entradaInventario = await this.entradaInventario(
      entradaInventarioDto,
      sucursalId
    )

    return entradaInventario
  }
}
