import z from 'zod'
import { idTypeBaseSchema } from '@/domain/validators/id-type.schema'

export const facturacionSchema = {
  enviarCliente: z.boolean().default(true),
  ventaId: idTypeBaseSchema.numericId
}
