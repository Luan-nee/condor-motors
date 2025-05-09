import z from 'zod'
import { idTypeBaseSchema } from '@/domain/validators/id-type.schema'
import { Validator } from '@/domain/validators/validator'

const detalleProformaVentaSchema = {
  productoId: idTypeBaseSchema.numericId,
  cantidad: z.number().min(1)
}

export const proformaVentaSchema = {
  nombre: z
    .string()
    .trim()
    .min(2)
    .max(512)
    .refine((val) => Validator.isValidDescription(val), {
      message:
        'El nombre solo puede contener este set de caracteres: a-zA-Z0-9áéíóúñüÁÉÍÓÚÑÜ.,¡!¿?-()[]{}$%&*\'_"@#+'
    })
    .optional()
    .nullable(),
  empleadoId: idTypeBaseSchema.numericId,
  clienteId: idTypeBaseSchema.numericId.optional().nullable(),
  detalles: z
    .object({
      productoId: detalleProformaVentaSchema.productoId,
      cantidad: detalleProformaVentaSchema.cantidad
    })
    .array()
    .min(1)
}
