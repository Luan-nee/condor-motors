import z from 'zod'
import { Validator } from '../../validator'

// tipoPersonaId
export const ClienteSchema = {
  nombresApellidos: z
    .string()
    .trim()
    .min(2)
    .max(250, {
      message:
        'El Nombre y apellido esta excediendo el limite para ser un considreado un nombre'
    })
    .refine((val) => Validator.isValidFullName(val), {
      message:
        'El texto ingresado no cumple con los requisitos para ser un nombre y apellido'
    })
    .optional(),
  dni: z
    .string()
    .trim()
    .min(6)
    .max(9, { message: 'El DNI no puede contener 9 caracteres' })
    .refine((valor) => Validator.isValidDni(valor), {
      message: 'El texto ingresado no es apto para un DNI'
    })
    .optional(),
  razonSocial: z
    .string()
    .trim()
    .min(5)
    .refine((valor) => Validator.isValidFullName(valor), {
      message:
        'el nombre de la razon social no puede contener caracteres especiales'
    })
    .optional(),
  ruc: z
    .string()
    .trim()
    .min(10)
    .max(12, { message: 'El ruc no puede ser mas de 12 caracteres' })
    .refine((valor) => Validator.isValidRuc(valor), {
      message: 'El ruc Ingresado no tiene caractes validos'
    })
    .optional(),
  telefono: z
    .string()
    .trim()
    .min(5)
    .max(7)
    .max(10)
    .refine((valor) => Validator.isOnlyNumbers(valor))
    .optional(),
  correo: z
    .string()
    .trim()
    .email({ message: 'El texto ingresado no es un correo' }),
  tipoPersonaId: z.number()
}
