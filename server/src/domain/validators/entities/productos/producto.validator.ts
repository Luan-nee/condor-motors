import { productoSchema } from './producto.schema'
import z from 'zod'

const createProductoSchema = z.object({
  sku: productoSchema.sku,
  nombre: productoSchema.nombre,
  descripcion: productoSchema.descripcion,
  maxDiasSinReabastecer: productoSchema.maxDiasSinReabastecer,
  unidadId: productoSchema.unidadId,
  categoriaId: productoSchema.categoriaId,
  marcaId: productoSchema.marcaId
})

export const createProductoValidator = (object: unknown) =>
  createProductoSchema.safeParse(object)
