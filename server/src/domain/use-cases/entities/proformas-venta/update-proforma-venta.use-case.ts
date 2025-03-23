import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { fixedTwoDecimals, productWithTwoDecimals } from '@/core/lib/utils'
import { db } from '@/db/connection'
import {
  detallesProductoTable,
  productosTable,
  proformasVentaTable
} from '@/db/schema'
import type { UpdateProformaVentaDto } from '@/domain/dtos/entities/proformas-venta/update-proforma-venta.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq, or } from 'drizzle-orm'

interface DetalleProformaVenta {
  id: number
  nombre: string
  cantidadMinimaDescuento: number | null
  cantidadGratisDescuento: number | null
  porcentajeDescuento: number | null
  precioVenta: string
  precioOferta: string | null
  detallesProductoId: number
  stock: number
  liquidacion: boolean
}

export class UpdateProformaVenta {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.proformasVenta.updateAny
  private readonly permissionRelated =
    permissionCodes.proformasVenta.updateRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async updateProformaVenta(
    numericIdDto: NumericIdDto,
    sucursalId: SucursalIdType,
    updateProformaVentaDto: UpdateProformaVentaDto,
    detallesProformaVenta?: DetalleProformaVenta[]
  ) {
    let detalles = undefined
    let total = undefined

    if (detallesProformaVenta !== undefined) {
      const detallesMap = new Map(
        updateProformaVentaDto.detalles?.map((detalle) => [
          detalle.productoId,
          detalle
        ])
      )

      const { detallesCalculados, total: totalNum } = this.calcularDetalles(
        detallesProformaVenta,
        detallesMap
      )

      detalles = detallesCalculados
      total = fixedTwoDecimals(totalNum)
    }

    const now = new Date()

    const results = await db
      .update(proformasVentaTable)
      .set({
        nombre: updateProformaVentaDto.nombre,
        total,
        detalles,
        fechaActualizacion: now
      })
      .where(
        and(
          eq(proformasVentaTable.id, numericIdDto.id),
          eq(proformasVentaTable.sucursalId, sucursalId)
        )
      )
      .returning({ id: proformasVentaTable.id })

    if (results.length < 1) {
      throw CustomError.badRequest(
        `No se pudo actualizar la proforma de venta con el id ${numericIdDto.id} (No encontrada)`
      )
    }

    const [proformaVenta] = results

    return proformaVenta
  }

  private calcularDetalles(
    detallesProformaVenta: DetalleProformaVenta[],
    detallesMap: Map<number, { productoId: number; cantidad: number }>
  ) {
    let total = 0

    const detallesCalculados = detallesProformaVenta.map((detalle) => {
      const detalleProforma = detallesMap.get(detalle.id)
      const cantidad = detalleProforma?.cantidad ?? 1

      const {
        precioUnitario,
        precioOriginal,
        cantidadGratis,
        descuento,
        cantidadPagada
      } = this.calcularPrecioYDescuento(detalle, cantidad)

      const cantidadTotal = cantidadPagada + cantidadGratis
      const subtotal = productWithTwoDecimals(precioUnitario, cantidadPagada)
      total += subtotal

      return {
        productoId: detalle.id,
        nombre: detalle.nombre,
        cantidadGratis,
        descuento,
        cantidadPagada,
        cantidadTotal,
        precioUnitario,
        precioOriginal,
        subtotal
      }
    })

    return { detallesCalculados, total }
  }

  private calcularPrecioYDescuento(
    detalle: DetalleProformaVenta,
    cantidad: number
  ) {
    let precioUnitario = Number(detalle.precioVenta)
    let precioOriginal = precioUnitario
    const cantidadGratis = 0
    const descuento = 0
    const cantidadPagada = cantidad

    if (detalle.precioOferta !== null && detalle.liquidacion) {
      precioUnitario = Number(detalle.precioOferta)
      precioOriginal = precioUnitario
    }

    if (
      detalle.cantidadMinimaDescuento === null ||
      cantidad < detalle.cantidadMinimaDescuento
    ) {
      return {
        precioUnitario,
        precioOriginal,
        cantidadGratis,
        descuento,
        cantidadPagada
      }
    }

    if (detalle.cantidadGratisDescuento !== null) {
      return {
        precioUnitario,
        precioOriginal,
        cantidadGratis: detalle.cantidadGratisDescuento,
        descuento,
        cantidadPagada: cantidad - detalle.cantidadGratisDescuento
      }
    }

    if (detalle.porcentajeDescuento !== null) {
      return {
        precioUnitario: productWithTwoDecimals(
          precioUnitario * (1 - detalle.porcentajeDescuento / 100),
          1
        ),
        precioOriginal,
        cantidadGratis,
        descuento: detalle.porcentajeDescuento,
        cantidadPagada
      }
    }

    return {
      precioUnitario,
      precioOriginal,
      cantidadGratis,
      descuento,
      cantidadPagada
    }
  }

  private validateDuplicates(updateProformaVentaDto: UpdateProformaVentaDto) {
    if (updateProformaVentaDto.detalles === undefined) {
      return [0]
    }

    const productoIds = new Set<number>()
    const duplicateProductoIds = new Set<number>()

    for (const { productoId } of updateProformaVentaDto.detalles) {
      if (productoIds.has(productoId)) {
        duplicateProductoIds.add(productoId)
      } else {
        productoIds.add(productoId)
      }
    }

    if (duplicateProductoIds.size > 0) {
      throw CustomError.badRequest(
        `Existen productos duplicados en los detalles: ${[...duplicateProductoIds].join(', ')}`
      )
    }

    return productoIds
  }

  private async validateRelated(
    updateProformaVentaDto: UpdateProformaVentaDto,
    sucursalId: SucursalIdType
  ) {
    if (
      updateProformaVentaDto.detalles === undefined ||
      updateProformaVentaDto.detalles.length < 1
    ) {
      return
    }

    const productoIds = this.validateDuplicates(updateProformaVentaDto)

    const productosConditionals = Array.from(productoIds).map((id) =>
      eq(productosTable.id, id)
    )

    const productos = await db
      .select({
        id: productosTable.id,
        nombre: productosTable.nombre,
        cantidadMinimaDescuento: productosTable.cantidadMinimaDescuento,
        cantidadGratisDescuento: productosTable.cantidadGratisDescuento,
        porcentajeDescuento: productosTable.porcentajeDescuento,
        precioVenta: detallesProductoTable.precioVenta,
        precioOferta: detallesProductoTable.precioOferta,
        detallesProductoId: detallesProductoTable.id,
        stock: detallesProductoTable.stock,
        liquidacion: detallesProductoTable.liquidacion
      })
      .from(productosTable)
      .innerJoin(
        detallesProductoTable,
        and(
          eq(productosTable.id, detallesProductoTable.productoId),
          eq(detallesProductoTable.sucursalId, sucursalId)
        )
      )
      .where(or(...productosConditionals))

    const productosMap = new Map(productos.map((p) => [p.id, p]))

    const invalidProducts: number[] = []
    const invalidStock: number[] = []

    for (const detalle of updateProformaVentaDto.detalles) {
      const producto = productosMap.get(detalle.productoId)

      if (producto === undefined) {
        invalidProducts.push(detalle.productoId)
      } else if (detalle.cantidad > producto.stock) {
        invalidStock.push(detalle.productoId)
      }
    }

    if (invalidProducts.length > 0) {
      throw CustomError.badRequest(
        `Estos productos no existen en su sucursal: ${invalidProducts.join(', ')}`
      )
    }

    if (invalidStock.length > 0) {
      throw CustomError.badRequest(
        `Estos productos no tienen el stock suficiente: ${invalidStock.join(', ')}`
      )
    }

    return productos
  }

  private async validatePermissions(sucursalId: SucursalIdType) {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny, this.permissionRelated]
    )

    let hasPermissionAny = false
    let hasPermissionRelated = false
    let isSameSucursal = false

    for (const permission of validPermissions) {
      if (permission.codigoPermiso === this.permissionAny) {
        hasPermissionAny = true
      }
      if (permission.codigoPermiso === this.permissionRelated) {
        hasPermissionRelated = true
      }
      if (permission.sucursalId === sucursalId) {
        isSameSucursal = true
      }

      if (hasPermissionAny || (hasPermissionRelated && isSameSucursal)) {
        return
      }
    }

    throw CustomError.forbidden()
  }

  async execute(
    numericIdDto: NumericIdDto,
    updateProformaVentaDto: UpdateProformaVentaDto,
    sucursalId: SucursalIdType
  ) {
    await this.validatePermissions(sucursalId)

    const detallesProformaVenta = await this.validateRelated(
      updateProformaVentaDto,
      sucursalId
    )

    const proformaVenta = await this.updateProformaVenta(
      numericIdDto,
      sucursalId,
      updateProformaVentaDto,
      detallesProformaVenta
    )

    return proformaVenta
  }
}
