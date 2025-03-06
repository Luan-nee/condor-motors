import { productoSchema } from '@domain/validators/entities/productos/producto.schema'
import z from 'zod'

const createProductoSchema = z.object({
  sku: productoSchema.sku,
  nombre: productoSchema.nombre,
  descripcion: productoSchema.descripcion,
  maxDiasSinReabastecer: productoSchema.maxDiasSinReabastecer,
  unidadId: productoSchema.unidadId,
  categoriaId: productoSchema.categoriaId,
  marcaId: productoSchema.marcaId,
  precioBase: productoSchema.precioBase,
  precioMayorista: productoSchema.precioMayorista,
  precioOferta: productoSchema.precioOferta,
  stock: productoSchema.stock
})

export const createProductoValidator = (object: unknown) =>
  createProductoSchema.safeParse(object)
