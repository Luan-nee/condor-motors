import { z } from 'zod'
import { Validator } from '@domain/validators/validator'
import { idTypeBaseSchema } from '@/domain/validators/id-type.schema'

export const empleadoSchema = {
  nombre: z
    .string()
    .trim()
    .min(2)
    .max(255)
    .refine((val) => Validator.isOnlyLettersSpaces(val), {
      message:
        'El nombre del empleado solo puede contener letras (mayúsculas o minúsculas)'
    }),
  apellidos: z
    .string()
    .trim()
    .min(2)
    .max(255)
    .refine((val) => Validator.isOnlyLettersSpaces(val), {
      message:
        'El apellido del empleado solo puede contener letras (mayúsculas o minúsculas)'
    }),
  activo: z
    .preprocess((val) => {
      if (typeof val === 'string') {
        if (val === 'true') return true
        if (val === 'false') return false
      }
      return val
    }, z.boolean())
    .default(true),
  dni: z
    .string()
    .trim()
    .length(8)
    .refine((val) => Validator.isOnlyNumbers(val), {
      message: 'El dni del empleado solo puede contener números'
    })
    .optional()
    .nullable(),
  celular: z
    .string()
    .trim()
    .length(9)
    .refine((val) => Validator.isOnlyNumbers(val), {
      message: 'El celular del empleado solo puede contener números'
    })
    .optional()
    .nullable(),
  horaInicioJornada: z
    .string()
    .time({
      message: 'El formato esperado es el siguiente: hh:mm:ss'
    })
    .optional()
    .nullable(),
  horaFinJornada: z
    .string()
    .time({
      message: 'El formato esperado es el siguiente: hh:mm:ss'
    })
    .optional()
    .nullable(),
  fechaContratacion: z
    .string()
    .date('El formato esperado es el siguiente: yyyy-mm-dd')
    .optional()
    .nullable(),
  sueldo: z.coerce.number().min(0).max(20000).optional().nullable(),
  sucursalId: idTypeBaseSchema.numericId
}
