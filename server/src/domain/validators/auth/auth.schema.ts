import { z } from 'zod'

export const userSchema = {
  usuario: z
    .string({
      message: 'El nombre de usuario debe ser de tipo string'
    })
    .min(4)
    .max(20)
    .refine((val) => /^[a-zA-Z]+$/.test(val), {
      message:
        'El nombre de usuario debe contener solo letras (mayúsculas o minúsculas)'
    }),
  clave: z
    .string({
      message: 'La clave debe ser de tipo string'
    })
    .min(6)
    .max(20)
    .refine(
      (val) => !/\s/g.test(val) && /[a-zA-Z]/.test(val) && /\d/.test(val),
      {
        message:
          'Contraseña no válida, esta debe contener al menos 6 caracteres, entre letras y números'
      }
    ),
  rolCuentaEmpleadoId: z.number({
    message: 'El id del rol de la cuenta del empleado debe ser de tipo number'
  }),
  empleadoId: z.number({
    message: 'El id del rol de la cuenta del empleado debe ser de tipo number'
  })
}

export const authPayloadSchema = {
  id: z.number().positive()
}
