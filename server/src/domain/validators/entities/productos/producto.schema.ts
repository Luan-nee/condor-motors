import { z } from 'zod'
import { idTypeBaseSchema } from '@/domain/validators/id-type.schema'
import { Validator } from '@/domain/validators/validator'
import { parseBoolString, parseNullString } from '@/core/lib/utils'

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
    .max(1023)
    .refine((val) => val === '' || Validator.isValidDescription(val), {
      message:
        'La descripción solo puede contener este set de caracteres: a-zA-Z0-9áéíóúñüÁÉÍÓÚÑÜ.,¡!¿?-()[]{}$%&*\'_"@#+'
    })
    .optional()
    .nullable(),
  maxDiasSinReabastecer: z.coerce.number().positive().optional().nullable(),
  stockMinimo: z.coerce.number().min(0).optional().nullable(),
  cantidadMinimaDescuento: z.coerce
    .number()
    .transform((val) => (val < 1 ? null : val))
    .optional()
    .nullable(),
  cantidadGratisDescuento: z.coerce
    .number()
    .min(0)
    .transform((val) => (val < 1 ? null : val))
    .optional()
    .nullable(),
  porcentajeDescuento: z.coerce
    .number()
    .min(0)
    .max(100)
    .transform((val) => (val < 1 ? null : val))
    .optional()
    .nullable(),
  colorId: idTypeBaseSchema.numericId,
  categoriaId: idTypeBaseSchema.numericId,
  marcaId: idTypeBaseSchema.numericId,
  precioCompra: z.coerce.number().min(0),
  precioVenta: z.coerce.number().min(0),
  precioOferta: z.coerce.number().min(0).optional().nullable(),
  stock: z.coerce.number().min(0).default(0),
  liquidacion: z
    .preprocess((val) => {
      if (typeof val === 'boolean') return val

      return typeof val === 'string' ? parseBoolString(val) : undefined
    }, z.boolean())
    .default(false)
}

export const queriesProductoSchema = {
  stockBajo: z.coerce.string().optional(),
  activo: z.coerce.string().optional(),
  stock: z.coerce
    .string()
    .transform((val) => {
      const [num, filterType] = val.split(',')
      const isValidValue = Validator.isOnlyNumbers(num)
      const nullValue = parseNullString(num)

      if (!isValidValue && nullValue !== null) {
        return undefined
      }

      const value = isValidValue ? Number(num) : 0

      return {
        value,
        filterType
      }
    })
    .optional()
}
