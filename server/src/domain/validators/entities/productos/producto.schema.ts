import { z } from 'zod'
import { idTypeBaseSchema } from '@/domain/validators/id-type.schema'
import { Validator } from '@/domain/validators/validator'

export const productoSchema = {
  nombre: z
    .string()
    .trim()
    .min(2)
    .max(250)
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
    .optional()
    .nullable(),
  maxDiasSinReabastecer: z.number().positive().optional().nullable(),
  stockMinimo: z.number().min(0).optional().nullable(),
  cantidadMinimaDescuento: z.number().min(1).optional().nullable(),
  cantidadGratisDescuento: z
    .number()
    .min(0)
    .transform((val) => (val < 1 ? null : val))
    .optional()
    .nullable(),
  porcentajeDescuento: z
    .number()
    .min(0)
    .max(100)
    .transform((val) => (val < 1 ? null : val))
    .optional()
    .nullable(),
  colorId: idTypeBaseSchema.numericId,
  categoriaId: idTypeBaseSchema.numericId,
  marcaId: idTypeBaseSchema.numericId,
  precioCompra: z.number().min(0),
  precioVenta: z.number().min(0),
  precioOferta: z.number().min(0).optional().nullable(),
  stock: z.number().min(0).default(0),
  liquidacion: z.boolean().default(false)
}

export const queriesProductoSchema = {
  stockBajo: z.coerce.string().optional()
}
