import { orderValues, permissionCodes } from '@/consts'
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
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { ProductoEntityMapper } from '@/domain/mappers/producto-entity.mapper'
import type { SucursalIdType } from '@/types/schemas'
import { and, asc, desc, eq, ilike, or, type SQL } from 'drizzle-orm'

interface GetArgs {
  queriesDto: QueriesDto
  order: SQL
  whereCondition: SQL | undefined
  sucursalId: SucursalIdType
}

export class GetProductos {
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

  private readonly validSortBy = {
    nombre: productosTable.nombre,
    precioBase: detallesProductoTable.precioBase,
    precioMayorista: detallesProductoTable.precioMayorista,
    precioOferta: detallesProductoTable.precioOferta,
    stock: detallesProductoTable.stock,
    fechaCreacion: productosTable.fechaCreacion
  } as const

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private isValidSortBy(
    sortBy: string
  ): sortBy is keyof typeof this.validSortBy {
    return Object.keys(this.validSortBy).includes(sortBy)
  }

  private getSortByColumn(sortBy: string) {
    if (
      Object.keys(this.validSortBy).includes(sortBy) &&
      this.isValidSortBy(sortBy)
    ) {
      return this.validSortBy[sortBy]
    }

    return this.validSortBy.fechaCreacion
  }

  private async getRelatedProductos({
    queriesDto,
    order,
    whereCondition,
    sucursalId
  }: GetArgs) {
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
          whereCondition,
          eq(cuentasEmpleadosTable.id, this.authPayload.id),
          eq(sucursalesTable.id, sucursalId)
        )
      )
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))
  }

  private async getAnyProductos({
    queriesDto,
    order,
    whereCondition,
    sucursalId
  }: GetArgs) {
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
      .where(and(whereCondition, eq(sucursalesTable.id, sucursalId)))
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))
  }

  private async getProductos(
    queriesDto: QueriesDto,
    sucursalId: SucursalIdType,
    hasPermissionGetAny: boolean
  ) {
    const sortByColumn = this.getSortByColumn(queriesDto.sort_by)

    const order =
      queriesDto.order === orderValues.asc
        ? asc(sortByColumn)
        : desc(sortByColumn)

    const whereCondition =
      queriesDto.search.length > 0
        ? or(
            ilike(productosTable.nombre, `%${queriesDto.search}%`),
            ilike(productosTable.sku, `%${queriesDto.search}%`)
          )
        : undefined

    const args = {
      queriesDto,
      order,
      whereCondition,
      sucursalId
    }

    const productos = hasPermissionGetAny
      ? await this.getAnyProductos(args)
      : await this.getRelatedProductos(args)

    return productos
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

  async execute(queriesDto: QueriesDto, sucursalId: SucursalIdType) {
    const hasPermissionGetAny = await this.validatePermissions(sucursalId)

    const productos = await this.getProductos(
      queriesDto,
      sucursalId,
      hasPermissionGetAny
    )

    const mappedProductos = productos.map((producto) =>
      ProductoEntityMapper.fromObject(producto)
    )

    return mappedProductos
  }
}
