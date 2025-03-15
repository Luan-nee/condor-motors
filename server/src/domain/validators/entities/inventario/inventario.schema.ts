import z from 'zod'
import { idTypeBaseSchema } from '@/domain/validators/id-type.schema'

export const inventarioSchema = {
  productoId: idTypeBaseSchema.numericId,
  cantidad: z.number().min(1)
}
