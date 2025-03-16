import { z } from 'zod'
import { Validator } from '@/domain/validators/validator'

export const sucursalSchema = {
  nombre: z
    .string()
    .trim()
    .min(2)
    .max(255)
    .refine((val) => Validator.isValidGeneralName(val), {
      message:
        'El nombre solo puede contener este set de caracteres: a-zA-ZáéíóúÁÉÍÓÚñÑüÜ-_'
    }),
  direccion: z
    .string()
    .trim()
    .min(2)
    .max(255)
    .refine((val) => Validator.isValidAddress(val), {
      message:
        'La dirección solo puede contener este set de caracteres: a-zA-ZáéíóúÁÉÍÓÚñÑüÜ-_.,'
    })
    .optional(),
  sucursalCentral: z.boolean()
}
