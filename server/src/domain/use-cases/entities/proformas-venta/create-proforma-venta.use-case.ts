import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
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

export class CreateProformaVenta {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.productos.createAny
  private readonly permissionRelated = permissionCodes.productos.createRelated

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async createProformaVenta(
    createProformaVentaDto: CreateProformaVentaDto,
    sucursalId: SucursalIdType,
    detallesProformaVenta: Array<{
      id: number
      nombre: string
      precioVenta: string
      detallesProductoId: number
      stock: number
    }>
  ) {
    const mappedDetalles = detallesProformaVenta.map((detalle) => {
      const detalleProforma = createProformaVentaDto.detalles.find(
        (item) => item.productoId === detalle.id
      )

      const cantidad = detalleProforma?.cantidad ?? 1
      const precio = parseFloat(detalle.precioVenta)
      const subtotal = parseFloat((cantidad * precio).toFixed(2))

      return {
        productoId: detalle.id,
        nombre: detalle.nombre,
        cantidad,
        precioUnitario: precio,
        subtotal
      }
    })

    const now = new Date()

    const total = mappedDetalles.reduce(
      (prev, current) => current.precioUnitario + prev,
      0
    )

    const proformaVenta = await db
      .insert(proformasVentaTable)
      .values({
        nombre: createProformaVentaDto.nombre,
        total: total.toFixed(2),
        detalles: mappedDetalles,
        empleadoId: createProformaVentaDto.empleadoId,
        sucursalId,
        fechaCreacion: now,
        fechaActualizacion: now
      })
      .returning({ id: proformasVentaTable.id })

    return proformaVenta
  }

  private async validateRelated(
    createProformaVentaDto: CreateProformaVentaDto,
    sucursalId: SucursalIdType
  ) {
    const productoIds = createProformaVentaDto.detalles.map(
      (detalle) => detalle.productoId
    )
    const duplicateProductoIds = productoIds.filter(
      (id, index, self) => self.indexOf(id) !== index
    )

    if (duplicateProductoIds.length > 0) {
      throw CustomError.badRequest(
        `Existen productos duplicados en los detalles: ${[...new Set(duplicateProductoIds)].join(', ')}`
      )
    }

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

    const productosConditonals = createProformaVentaDto.detalles.map(
      (detalle) => eq(productosTable.id, detalle.productoId)
    )

    const productos = await db
      .select({
        id: productosTable.id,
        nombre: productosTable.nombre,
        precioVenta: detallesProductoTable.precioVenta,
        detallesProductoId: detallesProductoTable.id,
        stock: detallesProductoTable.stock
      })
      .from(productosTable)
      .innerJoin(
        detallesProductoTable,
        and(
          eq(productosTable.id, detallesProductoTable.productoId),
          eq(detallesProductoTable.sucursalId, sucursalId)
        )
      )
      .where(or(...productosConditonals))

    const invalidProducts = createProformaVentaDto.detalles.filter(
      (detalleProducto) =>
        !productos.some(
          (producto) => detalleProducto.productoId === producto.id
        )
    )

    if (invalidProducts.length > 0) {
      throw CustomError.badRequest(
        `Estos productos no existen en su sucursal: ${invalidProducts.map((prod) => prod.productoId).join(', ')}`
      )
    }

    const invalidStock = createProformaVentaDto.detalles.filter(
      (detalleProducto) =>
        productos.some((producto) => detalleProducto.cantidad > producto.stock)
    )

    if (invalidStock.length > 0) {
      throw CustomError.badRequest(
        `Estos productos no tienen el stock suficiente: ${invalidStock.map((prod) => prod.productoId).join(', ')}`
      )
    }

    return productos
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
