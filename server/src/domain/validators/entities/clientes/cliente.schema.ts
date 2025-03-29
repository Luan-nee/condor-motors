import z from 'zod'
import { Validator } from '@/domain/validators/validator'
import { idTypeBaseSchema } from '@/domain/validators/id-type.schema'

export const clienteSchema = {
  tipoDocumentoId: idTypeBaseSchema.numericId,
  numeroDocumento: z
    .string()
    .trim()
    .min(8)
    .max(15)
    .refine((valor) => Validator.isOnlyNumbersLetters(valor), {
      message: 'El numero de documento solo puede contener números y letras'
    })
    .optional()
    .nullable(),
  denominacion: z.string().trim().max(100),
  direccion: z.string().trim().max(100).optional().nullable(),
  correo: z.string().trim().email().optional().nullable(),
  telefono: z
    .string()
    .trim()
    .refine((valor) => Validator.isValidPhoneNumber(valor), {
      message:
        'El número de telefono solo puede contener números, espacios, guiones y el código de pais opcionalmente'
    })
    .optional()
    .nullable()
}
