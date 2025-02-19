import { userSchema } from '@domain/validators/auth/user.validator'
import { z } from 'zod'

const LoginUserSchema = z.object({
  usuario: userSchema.usuario,
  clave: userSchema.clave
})

export const loginUserValidator = (object: unknown) =>
  LoginUserSchema.safeParse(object)
