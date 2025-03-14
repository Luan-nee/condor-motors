import { z } from 'zod'
import { Validator } from '@domain/validators/validator'
import { idTypeBaseSchema } from '@/domain/validators/id-type.schema'

export const empleadoSchema = {
  nombre: z
    .string()
    .min(2)
    .max(255)
    .refine((val) => Validator.isOnlyLettersSpaces(val), {
      message:
        'El nombre del empleado solo puede contener letras (mayúsculas o minúsculas)'
    }),
  apellidos: z
    .string()
    .min(2)
    .max(255)
    .refine((val) => Validator.isOnlyLettersSpaces(val), {
      message:
        'El apellido del empleado solo puede contener letras (mayúsculas o minúsculas) o tiene espacios demas'
    }),
  activo: z.boolean().default(true),
  dni: z
    .string()
    .length(8)
    .refine((val) => Validator.isOnlyNumbers(val), {
      message: 'El dni del empleado solo puede contener números'
    }),
  celular: z
    .string()
    .length(9)
    .refine((val) => Validator.isOnlyNumbers(val), {
      message: 'El celular del empleado solo puede contener números'
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
  sucursalId: idTypeBaseSchema.numericId
}
