import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { detallesProductoTable, entradasInventariosTable } from '@/db/schema'
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
    sucursalId: SucursalIdType,
    currentStock: number
  ) {
    const now = new Date()
    const newStock = currentStock + entradaInventarioDto.cantidad

    try {
      const insertedResult = await db.transaction(async (tx) => {
        const [entradaInventario] = await db
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
          tx.rollback()
        }

        return entradaInventario
      })

      return insertedResult
    } catch (error) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar registar la entrada de inventario'
      )
    }
  }

  private async validateRelacionados(
    entradaInventarioDto: EntradaInventarioDto,
    sucursalId: SucursalIdType
  ) {
    const results = await db
      .select({
        currentStock: detallesProductoTable.stock
      })
      .from(detallesProductoTable)
      .where(
        and(
          eq(detallesProductoTable.sucursalId, sucursalId),
          eq(detallesProductoTable.productoId, entradaInventarioDto.productoId)
        )
      )

    if (results.length < 1) {
      throw CustomError.badRequest(
        'El producto especificado no se encontró en la sucursal especificada'
      )
    }

    const [result] = results

    return result
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

    const detalleProducto = await this.validateRelacionados(
      entradaInventarioDto,
      sucursalId
    )

    const entradaInventario = await this.entradaInventario(
      entradaInventarioDto,
      sucursalId,
      detalleProducto.currentStock
    )

    return entradaInventario
  }
}
