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
import { asc, desc, eq, ilike, or, type SQL } from 'drizzle-orm'

interface GetArgs {
  queriesDto: QueriesDto
  order: SQL
  whereCondition: SQL | undefined
}

export class GetAllProductos {
  private readonly authPayload: AuthPayload
  private readonly permissionGetAny = permissionCodes.productos.getAny
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

  private readonly validSortBy = {
    nombre: productosTable.nombre,
    precioCompra: detallesProductoTable.precioCompra,
    precioVenta: detallesProductoTable.precioVenta,
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

  private async getAnyProductos({
    queriesDto,
    order,
    whereCondition
  }: GetArgs) {
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
      .where(whereCondition)
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))
  }

  private async getProductos(queriesDto: QueriesDto) {
    const sortByColumn = this.getSortByColumn(queriesDto.sort_by)

    const order =
      queriesDto.order === orderValues.asc
        ? asc(sortByColumn)
        : desc(sortByColumn)

    const whereCondition =
      queriesDto.search.length > 0
        ? or(
            ilike(productosTable.nombre, `%${queriesDto.search}%`),
            ilike(coloresTable.nombre, `%${queriesDto.search}%`),
            ilike(categoriasTable.nombre, `%${queriesDto.search}%`),
            ilike(marcasTable.nombre, `%${queriesDto.search}%`)
          )
        : undefined

    const args = {
      queriesDto,
      order,
      whereCondition
    }

    const productos = await this.getAnyProductos(args)

    return productos
  }

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionGetAny]
    )

    const hasPermissionGetAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionGetAny
    )

    if (!hasPermissionGetAny) {
      throw CustomError.forbidden()
    }
  }

  async execute(queriesDto: QueriesDto) {
    await this.validatePermissions()

    const productos = await this.getProductos(queriesDto)

    return productos
  }
}
