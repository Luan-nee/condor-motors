import { orderValues, permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { parseBoolString } from '@/core/lib/utils'
import { db } from '@/db/connection'
import {
  categoriasTable,
  coloresTable,
  detallesProductoTable,
  marcasTable,
  productosTable,
  sucursalesTable
} from '@/db/schema'
import type { QueriesProductoDto } from '@/domain/dtos/entities/productos/queries-producto.dto'
import type { SucursalIdType } from '@/types/schemas'
import {
  and,
  asc,
  count,
  desc,
  eq,
  gt,
  gte,
  ilike,
  isNotNull,
  isNull,
  lt,
  lte,
  ne,
  or,
  type SQL
} from 'drizzle-orm'

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
    pathFoto: productosTable.pathFoto,
    color: coloresTable.nombre,
    categoria: categoriasTable.nombre,
    marca: marcasTable.nombre,
    fechaCreacion: productosTable.fechaCreacion,
    detalleProductoId: detallesProductoTable.id,
    precioCompra: detallesProductoTable.precioCompra,
    precioVenta: detallesProductoTable.precioVenta,
    precioOferta: detallesProductoTable.precioOferta,
    stock: detallesProductoTable.stock,
    stockBajo: detallesProductoTable.stockBajo,
    liquidacion: detallesProductoTable.liquidacion
  }

  private readonly validSortBy = {
    nombre: productosTable.nombre,
    precioCompra: detallesProductoTable.precioCompra,
    precioVenta: detallesProductoTable.precioVenta,
    precioOferta: detallesProductoTable.precioOferta,
    stock: detallesProductoTable.stock,
    fechaCreacion: productosTable.fechaCreacion,
    stockBajo: detallesProductoTable.stockBajo,
    liquidacion: detallesProductoTable.liquidacion
  } as const

  private readonly validDecimalFilter = {
    precioCompra: detallesProductoTable.precioCompra,
    precioVenta: detallesProductoTable.precioVenta,
    precioOferta: detallesProductoTable.precioOferta
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

  private isValidDecimalFilter(
    filter: string
  ): filter is keyof typeof this.validDecimalFilter {
    return Object.keys(this.validDecimalFilter).includes(filter)
  }

  private getDecimalFilterColumn(filter: string) {
    if (this.isValidDecimalFilter(filter)) {
      return this.validDecimalFilter[filter]
    }

    return undefined
  }

  private async getProductos(
    queriesProductoDto: QueriesProductoDto,
    sucursalId: SucursalIdType
  ) {
    const sortByColumn = this.getSortByColumn(queriesProductoDto.sort_by)

    const order =
      queriesProductoDto.order === orderValues.asc
        ? asc(sortByColumn)
        : desc(sortByColumn)

    const searchCondition =
      queriesProductoDto.search.length > 0
        ? or(
            ilike(productosTable.nombre, `%${queriesProductoDto.search}%`),
            ilike(productosTable.sku, `%${queriesProductoDto.search}%`),
            ilike(coloresTable.nombre, `%${queriesProductoDto.search}%`),
            ilike(categoriasTable.nombre, `%${queriesProductoDto.search}%`),
            ilike(marcasTable.nombre, `%${queriesProductoDto.search}%`)
          )
        : undefined

    const filterCondition = this.getFilterCondition(queriesProductoDto)

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
      .limit(queriesProductoDto.page_size)
      .offset(queriesProductoDto.page_size * (queriesProductoDto.page - 1))

    return productos
  }

  private getMetadata() {
    return {
      sortByOptions: Object.keys(this.validSortBy),
      filterOptions: Object.keys(this.validDecimalFilter)
    }
  }

  private getStockFilterCondition(stock: {
    value: number
    filterType?: string
  }) {
    if (stock.filterType === 'gte') {
      return gte(detallesProductoTable.stock, stock.value)
    }

    if (stock.filterType === 'lte') {
      return lte(detallesProductoTable.stock, stock.value)
    }

    if (stock.filterType === 'ne') {
      return ne(detallesProductoTable.stock, stock.value)
    }

    if (stock.value === 0) {
      return or(
        eq(detallesProductoTable.stock, stock.value),
        isNull(detallesProductoTable.stock)
      )
    }

    return eq(detallesProductoTable.stock, stock.value)
  }

  // eslint-disable-next-line complexity
  private getFilterCondition(queriesProductoDto: QueriesProductoDto) {
    const { stockBajo, activo, stock } = queriesProductoDto
    const conditions: Array<SQL | undefined> = []

    if (stockBajo !== undefined) {
      const stockBajoBoolean = parseBoolString(stockBajo)

      if (stockBajoBoolean !== undefined) {
        conditions.push(eq(detallesProductoTable.stockBajo, stockBajoBoolean))
      }
    }

    if (stock !== undefined) {
      conditions.push(this.getStockFilterCondition(stock))
    }

    if (activo !== undefined) {
      const activoBoolean = parseBoolString(activo)

      if (activoBoolean !== undefined) {
        if (activoBoolean) {
          conditions.push(isNotNull(detallesProductoTable.id))
        } else {
          conditions.push(isNull(detallesProductoTable.id))
        }
      }
    }

    const filterColumn = this.getDecimalFilterColumn(queriesProductoDto.filter)
    const filterValueNumber = parseFloat(queriesProductoDto.filter_value)

    if (filterColumn === undefined || isNaN(filterValueNumber)) {
      return and(...conditions)
    }

    const filterValueString = filterValueNumber.toFixed(2)

    if (queriesProductoDto.filter_type === 'eq') {
      conditions.push(eq(filterColumn, filterValueString))
    } else if (queriesProductoDto.filter_type === 'gt') {
      conditions.push(gt(filterColumn, filterValueString))
    } else if (queriesProductoDto.filter_type === 'lt') {
      conditions.push(lt(filterColumn, filterValueString))
    }

    return and(...conditions)
  }

  private async getPagination(
    queriesProductoDto: QueriesProductoDto,
    sucursalId: SucursalIdType
  ) {
    const searchCondition =
      queriesProductoDto.search.length > 0
        ? or(
            ilike(productosTable.nombre, `%${queriesProductoDto.search}%`),
            ilike(coloresTable.nombre, `%${queriesProductoDto.search}%`),
            ilike(categoriasTable.nombre, `%${queriesProductoDto.search}%`),
            ilike(marcasTable.nombre, `%${queriesProductoDto.search}%`)
          )
        : undefined

    const filterCondition = this.getFilterCondition(queriesProductoDto)

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

    const totalPages = Math.ceil(
      totalItems.count / queriesProductoDto.page_size
    )
    const hasNext =
      queriesProductoDto.page < totalPages && queriesProductoDto.page >= 1
    const hasPrev =
      queriesProductoDto.page > 1 && queriesProductoDto.page <= totalPages

    return {
      totalItems: totalItems.count,
      totalPages,
      currentPage: queriesProductoDto.page,
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

  async execute(
    queriesProductoDto: QueriesProductoDto,
    sucursalId: SucursalIdType
  ) {
    await this.validatePermissions(sucursalId)

    const metadata = this.getMetadata()
    const pagination = await this.getPagination(queriesProductoDto, sucursalId)

    const isValidPage =
      (pagination.currentPage <= pagination.totalPages ||
        pagination.currentPage >= 1) &&
      pagination.totalItems > 0

    const results = isValidPage
      ? await this.getProductos(queriesProductoDto, sucursalId)
      : []

    return {
      results,
      pagination,
      metadata
    }
  }
}
