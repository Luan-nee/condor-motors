import { productoSchema } from '@domain/validators/entities/productos/producto.schema'
import z from 'zod'

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

export const updateProductoValidator = (object: unknown) =>
  createProductoSchema.partial().safeParse(object)
