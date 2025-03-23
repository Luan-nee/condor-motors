import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { fixedTwoDecimals, productWithTwoDecimals } from '@/core/lib/utils'
import { db } from '@/db/connection'
import {
  detallesProductoTable,
  empleadosTable,
  productosTable,
  proformasVentaTable,
  sucursalesTable
} from '@/db/schema'
import type { CreateProformaVentaDto } from '@/domain/dtos/entities/proformas-venta/create-proforma-venta.dto'
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

export class CreateProformaVenta {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.proformasVenta.createAny
  private readonly permissionRelated =
    permissionCodes.proformasVenta.createRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async createProformaVenta(
    createProformaVentaDto: CreateProformaVentaDto,
    sucursalId: SucursalIdType,
    detallesProformaVenta: DetalleProformaVenta[]
  ) {
    const detallesMap = new Map(
      createProformaVentaDto.detalles.map((detalle) => [
        detalle.productoId,
        detalle
      ])
    )

    const { detallesCalculados, total } = this.calcularDetalles(
      detallesProformaVenta,
      detallesMap
    )

    const now = new Date()

    const results = await db
      .insert(proformasVentaTable)
      .values({
        nombre: createProformaVentaDto.nombre,
        total: fixedTwoDecimals(total),
        detalles: detallesCalculados,
        empleadoId: createProformaVentaDto.empleadoId,
        sucursalId,
        fechaCreacion: now,
        fechaActualizacion: now
      })
      .returning({ id: proformasVentaTable.id })

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
    const precioOriginal = precioUnitario
    const cantidadGratis = 0
    const descuento = 0
    const cantidadPagada = cantidad

    if (detalle.precioOferta !== null && detalle.liquidacion) {
      precioUnitario = Number(detalle.precioOferta)
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

  private async validateSucursalEmpleado(
    createProformaVentaDto: CreateProformaVentaDto,
    sucursalId: SucursalIdType
  ) {
    const results = await db
      .select({
        sucursalId: sucursalesTable.id,
        empleadoId: empleadosTable.id
      })
      .from(sucursalesTable)
      .leftJoin(
        empleadosTable,
        eq(empleadosTable.id, createProformaVentaDto.empleadoId)
      )
      .where(eq(sucursalesTable.id, sucursalId))

    if (results.length < 1) {
      throw CustomError.badRequest('La sucursal que intentó asignar no existe')
    }

    const [result] = results

    if (result.empleadoId === null) {
      throw CustomError.badRequest('El empleado que intentó asignar no existe')
    }
  }

  private async validateRelated(
    createProformaVentaDto: CreateProformaVentaDto,
    sucursalId: SucursalIdType
  ) {
    const productoIds = new Set<number>()
    const duplicateProductoIds = new Set<number>()

    for (const { productoId } of createProformaVentaDto.detalles) {
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

    if (productoIds.size < 1) {
      return []
    }

    await this.validateSucursalEmpleado(createProformaVentaDto, sucursalId)

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

    for (const detalle of createProformaVentaDto.detalles) {
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
    createProformaVentaDto: CreateProformaVentaDto,
    sucursalId: SucursalIdType
  ) {
    await this.validatePermissions(sucursalId)

    const detallesProformaVenta = await this.validateRelated(
      createProformaVentaDto,
      sucursalId
    )

    const proformaVenta = await this.createProformaVenta(
      createProformaVentaDto,
      sucursalId,
      detallesProformaVenta
    )

    return proformaVenta
  }
}
