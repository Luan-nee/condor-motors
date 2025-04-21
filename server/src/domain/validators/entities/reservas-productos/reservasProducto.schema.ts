import z from 'zod'
import { idTypeBaseSchema } from '../../id-type.schema'

export const ReservasProductoSchema = {
  descripcion: z.string().trim().optional().nullable(),
  detallesReserva: z
    .object({
      nombreProducto: z.string(),
      precioCompra: z.number().positive(),
      precioVenta: z.number().positive(),
      cantidad: z.number().positive(),
      total: z.number().positive()
    })
    .array()
    .min(1),
  montoAdelantado: z.number().positive(),
  fechaRecojo: z.string().date().optional().nullable(),
  clienteId: idTypeBaseSchema.numericId,
  sucursalId: idTypeBaseSchema.numericId.optional().nullable()
}
