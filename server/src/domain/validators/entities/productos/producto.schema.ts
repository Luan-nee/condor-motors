import { z } from 'zod'
import { idTypeBaseSchema } from '@/domain/validators/id-type.schema'
import { Validator } from '@/domain/validators/validator'

export const productoSchema = {
  nombre: z
    .string()
    .trim()
    .min(2)
    .max(255)
    .refine((val) => Validator.isValidGeneralName(val), {
      message:
        'El nombre solo puede contener este set de caracteres: a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ-_'
    }),
  descripcion: z
    .string()
    .trim()
    .min(2)
    .max(1023)
    .refine((val) => Validator.isValidDescription(val), {
      message:
        'La descripción solo puede contener este set de caracteres: a-zA-Z0-9áéíóúñüÁÉÍÓÚÑÜ.,¡!¿?-()[]{}$%&*\'_"@#+'
    })
    .optional(),
  maxDiasSinReabastecer: z.number().positive().optional(),
  stockMinimo: z.number().min(0).optional(),
  cantidadMinimaDescuento: z.number().min(1).optional(),
  cantidadGratisDescuento: z.number().min(1).optional(),
  porcentajeDescuento: z.number().min(0).max(100).optional(),
  colorId: idTypeBaseSchema.numericId,
  categoriaId: idTypeBaseSchema.numericId,
  marcaId: idTypeBaseSchema.numericId,
  precioCompra: z.number().min(0).optional(),
  precioVenta: z.number().min(0).optional(),
  precioOferta: z.number().min(0).optional(),
  stock: z.number().min(0).default(0).optional()
}
