import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  categoriasTable,
  coloresTable,
  cuentasEmpleadosTable,
  detallesProductoTable,
  empleadosTable,
  marcasTable,
  productosTable,
  sucursalesTable
} from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq } from 'drizzle-orm'

export class GetProductoById {
  private readonly authPayload: AuthPayload
  private readonly permissionGetAny = permissionCodes.productos.getAny
  private readonly permissionGetRelated = permissionCodes.productos.getRelated
  private readonly selectFields = {
    id: productosTable.id,
    nombre: productosTable.nombre,
    descripcion: productosTable.descripcion,
    maxDiasSinReabastecer: productosTable.maxDiasSinReabastecer,
    stockMinimo: productosTable.stockMinimo,
    cantidadMinimaDescuento: productosTable.cantidadMinimaDescuento,
    cantidadGratisDescuento: productosTable.cantidadGratisDescuento,
    porcentajeDescuento: productosTable.porcentajeDescuento,
    color: coloresTable.nombre,
    categoria: categoriasTable.nombre,
    marca: marcasTable.nombre,
    fechaCreacion: productosTable.fechaCreacion,
    detalleProductoId: detallesProductoTable.id,
    precioCompra: detallesProductoTable.precioCompra,
    precioVenta: detallesProductoTable.precioVenta,
    precioOferta: detallesProductoTable.precioOferta,
    stock: detallesProductoTable.stock,
    stockBajo: detallesProductoTable.stockBajo
  }

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async getRelated(
    numericIdDto: NumericIdDto,
    sucursalId: SucursalIdType
  ) {
    return await db
      .select(this.selectFields)
      .from(productosTable)
      .innerJoin(coloresTable, eq(coloresTable.id, productosTable.colorId))
      .innerJoin(
        categoriasTable,
        eq(categoriasTable.id, productosTable.categoriaId)
      )
      .innerJoin(marcasTable, eq(marcasTable.id, productosTable.marcaId))
      .innerJoin(
        detallesProductoTable,
        eq(detallesProductoTable.productoId, productosTable.id)
      )
      .innerJoin(
        sucursalesTable,
        eq(sucursalesTable.id, detallesProductoTable.sucursalId)
      )
      .innerJoin(
        empleadosTable,
        eq(empleadosTable.sucursalId, sucursalesTable.id)
      )
      .innerJoin(
        cuentasEmpleadosTable,
        eq(cuentasEmpleadosTable.empleadoId, empleadosTable.id)
      )
      .where(
        and(
          eq(productosTable.id, numericIdDto.id),
          eq(detallesProductoTable.sucursalId, sucursalId),
          eq(cuentasEmpleadosTable.id, this.authPayload.id)
        )
      )
  }

  private async getAny(numericIdDto: NumericIdDto, sucursalId: SucursalIdType) {
    return await db
      .select(this.selectFields)
      .from(productosTable)
      .innerJoin(coloresTable, eq(coloresTable.id, productosTable.colorId))
      .innerJoin(
        categoriasTable,
        eq(categoriasTable.id, productosTable.categoriaId)
      )
      .innerJoin(marcasTable, eq(marcasTable.id, productosTable.marcaId))
      .innerJoin(
        detallesProductoTable,
        eq(detallesProductoTable.productoId, productosTable.id)
      )
      .innerJoin(
        sucursalesTable,
        eq(sucursalesTable.id, detallesProductoTable.sucursalId)
      )
      .where(
        and(
          eq(productosTable.id, numericIdDto.id),
          eq(detallesProductoTable.sucursalId, sucursalId)
        )
      )
  }

  private async getProductoById(
    numericIdDto: NumericIdDto,
    sucursalId: SucursalIdType,
    hasPermissionGetAny: boolean
  ) {
    const productos = hasPermissionGetAny
      ? await this.getAny(numericIdDto, sucursalId)
      : await this.getRelated(numericIdDto, sucursalId)

    if (productos.length < 1) {
      throw CustomError.badRequest(
        `No se encontró ningún producto con el id '${numericIdDto.id}'`
      )
    }

    const [producto] = productos

    return producto
  }

  private async validatePermissions(sucursalId: SucursalIdType) {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionGetAny, this.permissionGetRelated]
    )

    const hasPermissionGetAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionGetAny
    )

    if (
      !hasPermissionGetAny &&
      !validPermissions.some(
        (permission) => permission.codigoPermiso === this.permissionGetRelated
      )
    ) {
      throw CustomError.forbidden()
    }

    const isSameSucursal = validPermissions.some(
      (permission) => permission.sucursalId === sucursalId
    )

    if (!hasPermissionGetAny && !isSameSucursal) {
      throw CustomError.forbidden()
    }

    return hasPermissionGetAny
  }

  async execute(numericIdDto: NumericIdDto, sucursalId: SucursalIdType) {
    const hasPermissionGetAny = await this.validatePermissions(sucursalId)

    const producto = await this.getProductoById(
      numericIdDto,
      sucursalId,
      hasPermissionGetAny
    )

    return producto
  }
}
