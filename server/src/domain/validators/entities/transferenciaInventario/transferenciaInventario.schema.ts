import z from 'zod'
import { idTypeBaseSchema } from '../../id-type.schema'

export const transferenciaInventarioSchema = {
  empleadoId: idTypeBaseSchema.numericId,
  estadoTransferenciaId: idTypeBaseSchema.numericId,
  sucursalOrigenId: idTypeBaseSchema.numericId,
  sucursalDestinoId: idTypeBaseSchema.numericId,
  detalleVenta: z.object({
    cantidad: z.number().positive(),
    productoId: idTypeBaseSchema.numericId,
    transferenciaInventarioId: idTypeBaseSchema.numericId
  })
}
