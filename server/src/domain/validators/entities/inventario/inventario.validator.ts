import { inventarioSchema } from '@domain/validators/entities/inventario/inventario.schema'
import z from 'zod'

const entradaInventarioSchema = z.object({
  productoId: inventarioSchema.productoId,
  cantidad: inventarioSchema.cantidad
})

export const entradaInventarioValidator = (object: unknown) =>
  entradaInventarioSchema.safeParse(object)
