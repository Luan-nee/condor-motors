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
  razonSocial: z
    .string()
    .trim()
    .min(5)
    .refine((valor) => Validator.isValidFullName(valor), {
      message:
        'el nombre de la razon social no puede contener caracteres especiales'
    }),
  denominacion: z.string().trim(),
  codigoPais: z
    .string()
    .trim()
    .min(5)
    .max(7)
    .refine((valor) => Validator.isOnlyNumbers(valor)),
  direccion: z.string().trim().min(3).max(6),
  correo: z
    .string()
    .trim()
    .email({ message: 'El texto ingresado no es un correo' }),
  telefono: z
    .string()
    .trim()
    .refine((valor) => Validator.isOnlyNumbers(valor), {
      message: 'El telefono no contiene caracteres especiales'
    })
}
