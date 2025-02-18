import { z } from 'zod'
import { userSchema } from './user.validator'

const RegisterUserSchema = z.object({
  usuario: userSchema.usuario,
  clave: userSchema.clave,
  rolCuentaEmpleadoId: userSchema.rolCuentaEmpleadoId,
  empleadoId: userSchema.empleadoId
})

export const registerUserValidator = (object: unknown) =>
  RegisterUserSchema.safeParse(object)
