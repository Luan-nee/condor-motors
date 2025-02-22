import { paramsSchema } from '@domain/validators/query-params/query-params.schema'
import z from 'zod'

const ParamsNumericIdSchema = z.object({
  id: paramsSchema.id
})

export const paramsNumericIdValidator = (object: unknown) =>
  ParamsNumericIdSchema.safeParse(object)
