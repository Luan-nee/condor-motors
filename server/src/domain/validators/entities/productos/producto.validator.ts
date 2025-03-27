import {
  queriesProductoSchema,
  productoSchema
} from '@domain/validators/entities/productos/producto.schema'
import { queriesBaseSchema } from '@/domain/validators/query-params/query-params.schema'
import z from 'zod'

export const QueriesProductoSchema = z.object({
  sort_by: queriesBaseSchema.sort_by,
  order: queriesBaseSchema.order,
  page: queriesBaseSchema.page,
  search: queriesBaseSchema.search,
  page_size: queriesBaseSchema.page_size,
  filter: queriesBaseSchema.filter,
  filter_value: queriesBaseSchema.filter_value,
  filter_type: queriesBaseSchema.filter_type,
  stockBajo: queriesProductoSchema.stockBajo
})

export const queriesProductoValidator = (object: unknown) =>
  QueriesProductoSchema.safeParse(object)

const createProductoSchema = z.object({
  nombre: productoSchema.nombre,
  descripcion: productoSchema.descripcion,
  maxDiasSinReabastecer: productoSchema.maxDiasSinReabastecer,
  stockMinimo: productoSchema.stockMinimo,
  cantidadMinimaDescuento: productoSchema.cantidadMinimaDescuento,
  cantidadGratisDescuento: productoSchema.cantidadGratisDescuento,
  porcentajeDescuento: productoSchema.porcentajeDescuento,
  colorId: productoSchema.colorId,
  categoriaId: productoSchema.categoriaId,
  marcaId: productoSchema.marcaId,
  precioCompra: productoSchema.precioCompra,
  precioVenta: productoSchema.precioVenta,
  precioOferta: productoSchema.precioOferta,
  stock: productoSchema.stock
})

export const createProductoValidator = (object: unknown) =>
  createProductoSchema.safeParse(object)

const updateProductoSchema = z.object({
  nombre: productoSchema.nombre,
  descripcion: productoSchema.descripcion,
  maxDiasSinReabastecer: productoSchema.maxDiasSinReabastecer,
  stockMinimo: productoSchema.stockMinimo,
  cantidadMinimaDescuento: productoSchema.cantidadMinimaDescuento,
  cantidadGratisDescuento: productoSchema.cantidadGratisDescuento,
  porcentajeDescuento: productoSchema.porcentajeDescuento,
  colorId: productoSchema.colorId,
  categoriaId: productoSchema.categoriaId,
  marcaId: productoSchema.marcaId,
  precioCompra: productoSchema.precioCompra,
  precioVenta: productoSchema.precioVenta,
  precioOferta: productoSchema.precioOferta
})

export const updateProductoValidator = (object: unknown) =>
  updateProductoSchema.partial().safeParse(object)

const addProductoSchema = z.object({
  precioCompra: productoSchema.precioCompra,
  precioVenta: productoSchema.precioVenta,
  precioOferta: productoSchema.precioOferta,
  stock: productoSchema.stock
})

export const addProductoValidator = (object: unknown) =>
  addProductoSchema.safeParse(object)
