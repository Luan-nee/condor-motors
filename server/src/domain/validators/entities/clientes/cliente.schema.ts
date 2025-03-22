import z from 'zod'
import { Validator } from '../../validator'

// tipoPersonaId
export const ClienteSchema = {
  tipoDocumentoId: z.number(),
  numeroDocumento: z
    .string()
    .trim()
    .min(6)
    .max(13, { message: 'El Numero de documento ingresado no es valido' })
    .refine((valor) => Validator.isOnlyNumbers(valor), {
      message:
        'El numero de documento Ingresado no puede contener otro tipo de caracteres a parte de los numeros'
    }),
  denominacion: z.string().trim(),
  direccion: z.string().trim().min(3).optional(),
  correo: z
    .string()
    .trim()
    .email({ message: 'El texto ingresado no es un correo' })
    .optional(),
  telefono: z
    .string()
    .trim()
    .refine((valor) => Validator.isOnlyNumbers(valor), {
      message: 'El telefono no contiene caracteres especiales'
    })
    .optional()
}
