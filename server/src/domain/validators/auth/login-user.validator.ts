import { z } from 'zod'
import { userSchema } from './user.validator'

const LoginUserSchema = z.object({
  usuario: userSchema.usuario,
  clave: userSchema.clave
})

export const loginUserValidator = (object: unknown) =>
  LoginUserSchema.safeParse(object)
