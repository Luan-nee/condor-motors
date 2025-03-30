import z from 'zod'
import { idTypeBaseSchema } from '@/domain/validators/id-type.schema'
import { Validator } from '@/domain/validators/validator'

export const ventaSchema = {
  observaciones: z
    .string()
    .trim()
    .max(1000)
    .refine((val) => Validator.isValidDescription(val))
    .optional(),
  tipoDocumentoId: idTypeBaseSchema.numericId,
  detalles: z
    .object({
      productoId: idTypeBaseSchema.numericId,
      cantidad: z.number().min(1),
      tipoTaxId: idTypeBaseSchema.numericId,
      aplicarOferta: z.boolean().default(true)
    })
    .array()
    .min(1),
  monedaId: idTypeBaseSchema.numericId.optional(),
  metodoPagoId: idTypeBaseSchema.numericId.optional(),
  clienteId: idTypeBaseSchema.numericId,
  empleadoId: idTypeBaseSchema.numericId,
  fechaEmision: z
    .string()
    .date('El formato esperado es el siguiente: yyyy-mm-dd')
    .optional(),
  horaEmision: z
    .string()
    .time({
      message: 'El formato esperado es el siguiente: hh:mm:ss'
    })
    .optional(),
  motivoAnulado: z
    .string()
    .trim()
    .min(2)
    .refine((val) => Validator.isValidDescription(val))
}
