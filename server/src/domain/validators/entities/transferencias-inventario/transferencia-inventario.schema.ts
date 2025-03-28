import z from 'zod'
import { idTypeBaseSchema } from '@/domain/validators/id-type.schema'

export const transferenciaInvSchema = {
  sucursalOrigenId: idTypeBaseSchema.numericId,
  sucursalDestinoId: idTypeBaseSchema.numericId,
  items: z
    .object({
      productoId: idTypeBaseSchema.numericId,
      cantidad: z.number().min(1)
    })
    .array()
    .min(1)
}
