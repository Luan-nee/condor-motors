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
        'El nombre solo puede contener este set de caracteres: a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ-_'
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
    .optional()
    .nullable(),
  sucursalCentral: z.boolean(),
  serieFactura: z
    .string()
    .trim()
    .length(4)
    .startsWith('F')
    .toUpperCase()
    .optional()
    .nullable(),
  numeroFacturaInicial: z.number().int().min(1).optional().nullable(),
  serieBoleta: z
    .string()
    .trim()
    .length(4)
    .startsWith('B')
    .toUpperCase()
    .optional()
    .nullable(),
  numeroBoletaInicial: z.number().int().min(1).optional().nullable(),
  codigoEstablecimiento: z.string().trim().length(4).optional().nullable()
}
