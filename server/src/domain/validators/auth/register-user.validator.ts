import { userSchema } from '@/domain/validators/auth/auth.schema'
import { z } from 'zod'

const RegisterUserSchema = z.object({
  usuario: userSchema.usuario,
  clave: userSchema.clave,
  rolCuentaEmpleadoId: userSchema.rolCuentaEmpleadoId,
  empleadoId: userSchema.empleadoId
})

export const registerUserValidator = (object: unknown) =>
  RegisterUserSchema.safeParse(object)
