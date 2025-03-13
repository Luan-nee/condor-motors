import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  categoriasTable,
  cuentasEmpleadosTable,
  detallesProductoTable,
  empleadosTable,
  marcasTable,
  productosTable,
  sucursalesTable,
  unidadesTable
} from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { ProductoEntityMapper } from '@/domain/mappers/producto-entity.mapper'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq } from 'drizzle-orm'

export class GetProductoById {
  private readonly authPayload: AuthPayload
  private readonly permissionGetAny = permissionCodes.productos.getAny
  private readonly permissionGetRelated = permissionCodes.productos.getRelated
  private readonly selectFields = {
    id: productosTable.id,
    sku: productosTable.sku,
    nombre: productosTable.nombre,
    descripcion: productosTable.descripcion,
    maxDiasSinReabastecer: productosTable.maxDiasSinReabastecer,
    unidadId: productosTable.unidadId,
    categoriaId: productosTable.categoriaId,
    marcaId: productosTable.marcaId,
    fechaCreacion: productosTable.fechaCreacion,
    fechaActualizacion: productosTable.fechaActualizacion,
    precioBase: detallesProductoTable.precioBase,
    precioMayorista: detallesProductoTable.precioMayorista,
    precioOferta: detallesProductoTable.precioOferta,
    stock: detallesProductoTable.stock,
    relacionados: {
      unidadNombre: unidadesTable.nombre,
      categoriaNombre: categoriasTable.nombre,
      marcaNombre: marcasTable.nombre
    },
    sucursalId: sucursalesTable.id
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
      .innerJoin(unidadesTable, eq(unidadesTable.id, productosTable.unidadId))
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
      .innerJoin(unidadesTable, eq(unidadesTable.id, productosTable.unidadId))
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

    const mappedProducto = ProductoEntityMapper.fromObject(producto)

    return mappedProducto
  }
}
