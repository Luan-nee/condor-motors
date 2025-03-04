import { z } from 'zod'
import { Validator } from '@domain/validators/validator'

export const empleadoSchema = {
  nombre: z
    .string()
    .min(2)
    .max(255)
    .refine((val) => Validator.isOnlyLetters(val), {
      message:
        'El nombre del empleado solo puede contener letras (mayúsculas o minúsculas)'
    }),
  apellidos: z
    .string()
    .min(2)
    .max(255)
    .refine((val) => Validator.isOnlyLetters(val), {
      message:
        'El apellido del empleado solo puede contener letras (mayúsculas o minúsculas)'
    }),
  edad: z.number().min(1).max(99).optional(),
  dni: z
    .string()
    .length(8)
    .refine((val) => Validator.isOnlyNumbers(val), {
      message: 'El dni del empleado solo puede números'
    })
    .optional(),
  horaInicioJornada: z
    .string()
    .time({
      message: 'El formato esperado es el siguiente: hh:mm:ss'
    })
    .optional(),
  horaFinJornada: z
    .string()
    .time({
      message: 'El formato esperado es el siguiente: hh:mm:ss'
    })
    .optional(),
  fechaContratacion: z
    .string()
    .date('El formato esperado es el siguiente: yyyy-mm-dd')
    .optional(),
  sueldo: z.number().min(0).max(20000).optional(),
  sucursalId: z.number()
}
