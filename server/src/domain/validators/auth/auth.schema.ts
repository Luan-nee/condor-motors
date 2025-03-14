import { z } from 'zod'
import { idTypeBaseSchema } from '@/domain/validators/id-type.schema'

export const userSchema = {
  usuario: z
    .string()
    .min(4)
    .max(20)
    .refine((val) => /^[a-zA-Z]+$/.test(val), {
      message:
        'El nombre de usuario debe contener solo letras (mayúsculas o minúsculas) a excepción la letra ñ o letras con tilde'
    }),
  clave: z
    .string()
    .min(6)
    .max(20)
    .refine((val) => /^[a-zA-Z0-9]+$/.test(val) && /\d/.test(val), {
      message:
        'Contraseña no válida, esta debe contener al menos 6 caracteres, entre letras y números, y no debe contener espacios'
    }),
  rolCuentaEmpleadoId: idTypeBaseSchema.numericId,
  empleadoId: idTypeBaseSchema.numericId
}

export const authPayloadSchema = {
  id: idTypeBaseSchema.numericId
}
