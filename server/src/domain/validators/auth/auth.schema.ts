import { z } from 'zod'
import { idTypeBaseSchema } from '@/domain/validators/id-type.schema'
import { Validator } from '@/domain/validators/validator'

export const userSchema = {
  usuario: z
    .string()
    .trim()
    .min(4)
    .max(20)
    .refine((val) => Validator.isValidUsername(val), {
      message:
        'El nombre de usuario debe contener solo letras (mayúsculas o minúsculas) a excepción la letra ñ o letras con tilde'
    }),
  clave: z
    .string()
    .trim()
    .min(6)
    .max(20)
    .refine((val) => Validator.isValidPassword(val) && /\d/.test(val), {
      message:
        'Contraseña no válida, esta debe contener al menos 6 caracteres, entre letras y números, y no debe contener espacios'
    }),
  rolCuentaEmpleadoId: idTypeBaseSchema.numericId,
  empleadoId: idTypeBaseSchema.numericId
}

export const authPayloadSchema = {
  id: idTypeBaseSchema.numericId
}
