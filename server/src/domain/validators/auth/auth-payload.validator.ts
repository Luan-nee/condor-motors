import { authPayloadSchema } from '@/domain/validators/auth/auth.schema'
import z from 'zod'

const AuthPayloadSchema = z.object({
  id: authPayloadSchema.id
})

export const authPayloadValidator = (object: unknown) =>
  AuthPayloadSchema.safeParse(object)
