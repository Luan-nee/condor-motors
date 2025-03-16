import { z } from 'zod'
import { Validator } from '@/domain/validators/validator'

export const categoriasSchema = {
  nombre: z
    .string()
    .trim()
    .min(2)
    .max(255)
    .refine((val) => Validator.isValidGeneralName(val), {
      message:
        'El nombre solo puede contener este set de caracteres: a-zA-ZáéíóúÁÉÍÓÚñÑüÜ-_'
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
}
