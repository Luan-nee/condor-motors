import { orderValues, permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  categoriasTable,
  coloresTable,
  detallesProductoTable,
  marcasTable,
  productosTable,
  sucursalesTable
} from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, asc, count, desc, eq, gt, ilike, lt, or } from 'drizzle-orm'

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

  private readonly validSortBy = {
    nombre: productosTable.nombre,
    precioCompra: detallesProductoTable.precioCompra,
    precioVenta: detallesProductoTable.precioVenta,
    precioOferta: detallesProductoTable.precioOferta,
    stock: detallesProductoTable.stock,
    fechaCreacion: productosTable.fechaCreacion
  } as const

  private readonly validFilter = {
    precioCompra: detallesProductoTable.precioCompra,
    precioVenta: detallesProductoTable.precioVenta,
    precioOferta: detallesProductoTable.precioOferta
    // stock: detallesProductoTable.stock
    // fechaCreacion: productosTable.fechaCreacion
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
    if (this.isValidSortBy(sortBy)) {
      return this.validSortBy[sortBy]
    }

    return this.validSortBy.fechaCreacion
  }

  private isValidFilter(
    filter: string
  ): filter is keyof typeof this.validFilter {
    return Object.keys(this.validFilter).includes(filter)
  }

  private getFilterColumn(filter: string) {
    if (this.isValidFilter(filter)) {
      return this.validFilter[filter]
    }

    return undefined
  }

  private async getProductos(
    queriesDto: QueriesDto,
    sucursalId: SucursalIdType
  ) {
    const sortByColumn = this.getSortByColumn(queriesDto.sort_by)

    const order =
      queriesDto.order === orderValues.asc
        ? asc(sortByColumn)
        : desc(sortByColumn)

    const searchCondition =
      queriesDto.search.length > 0
        ? or(
            ilike(productosTable.nombre, `%${queriesDto.search}%`),
            ilike(coloresTable.nombre, `%${queriesDto.search}%`),
            ilike(categoriasTable.nombre, `%${queriesDto.search}%`),
            ilike(marcasTable.nombre, `%${queriesDto.search}%`)
          )
        : undefined

    const filterCondition = this.getFilterCondition(queriesDto)

    const whereCondition = and(searchCondition, filterCondition)

    const productos = await db
      .select(this.selectFields)
      .from(productosTable)
      .innerJoin(coloresTable, eq(coloresTable.id, productosTable.colorId))
      .innerJoin(
        categoriasTable,
        eq(categoriasTable.id, productosTable.categoriaId)
      )
      .innerJoin(marcasTable, eq(marcasTable.id, productosTable.marcaId))
      .leftJoin(
        detallesProductoTable,
        and(
          eq(productosTable.id, detallesProductoTable.productoId),
          eq(detallesProductoTable.sucursalId, sucursalId)
        )
      )
      .innerJoin(sucursalesTable, eq(sucursalesTable.id, sucursalId))
      .where(whereCondition)
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))

    return productos
  }

  private getMetadata() {
    return {
      sortByOptions: Object.keys(this.validSortBy),
      filterOptions: Object.keys(this.validFilter)
    }
  }

  private getFilterCondition(queriesDto: QueriesDto) {
    const filterColumn = this.getFilterColumn(queriesDto.filter)
    const filterValueNumber = parseFloat(queriesDto.filter_value)

    if (filterColumn === undefined || isNaN(filterValueNumber)) {
      return
    }

    const filterValueString = filterValueNumber.toFixed(2)

    if (queriesDto.filter_type === 'eq') {
      return eq(filterColumn, filterValueString)
    }

    if (queriesDto.filter_type === 'gt') {
      return gt(filterColumn, filterValueString)
    }

    if (queriesDto.filter_type === 'lt') {
      return lt(filterColumn, filterValueString)
    }
  }

  private async getPagination(
    queriesDto: QueriesDto,
    sucursalId: SucursalIdType
  ) {
    const searchCondition =
      queriesDto.search.length > 0
        ? or(
            ilike(productosTable.nombre, `%${queriesDto.search}%`),
            ilike(coloresTable.nombre, `%${queriesDto.search}%`),
            ilike(categoriasTable.nombre, `%${queriesDto.search}%`),
            ilike(marcasTable.nombre, `%${queriesDto.search}%`)
          )
        : undefined

    const filterCondition = this.getFilterCondition(queriesDto)

    const whereCondition = and(searchCondition, filterCondition)

    const results = await db
      .select({ count: count(productosTable.id) })
      .from(productosTable)
      .innerJoin(coloresTable, eq(coloresTable.id, productosTable.colorId))
      .innerJoin(
        categoriasTable,
        eq(categoriasTable.id, productosTable.categoriaId)
      )
      .innerJoin(marcasTable, eq(marcasTable.id, productosTable.marcaId))
      .leftJoin(
        detallesProductoTable,
        and(
          eq(productosTable.id, detallesProductoTable.productoId),
          eq(detallesProductoTable.sucursalId, sucursalId)
        )
      )
      .innerJoin(sucursalesTable, eq(sucursalesTable.id, sucursalId))
      .where(whereCondition)

    const [totalItems] = results

    const totalPages = Math.ceil(totalItems.count / queriesDto.page_size)
    const hasNext = queriesDto.page < totalPages && queriesDto.page >= 1
    const hasPrev = queriesDto.page > 1 && queriesDto.page <= totalPages

    return {
      totalItems: totalItems.count,
      totalPages,
      currentPage: queriesDto.page,
      hasNext,
      hasPrev
    }
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
  }

  async execute(queriesDto: QueriesDto, sucursalId: SucursalIdType) {
    await this.validatePermissions(sucursalId)

    const metadata = this.getMetadata()
    const pagination = await this.getPagination(queriesDto, sucursalId)

    const isValidPage =
      (pagination.currentPage <= pagination.totalPages ||
        pagination.currentPage >= 1) &&
      pagination.totalItems > 0

    const results = isValidPage
      ? await this.getProductos(queriesDto, sucursalId)
      : []

    return {
      results,
      pagination,
      metadata
    }
  }
}
