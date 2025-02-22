import z from 'zod'

export const querysSchema = {
  limit: z.coerce.number().positive().min(1).optional(),
  sort_by: z.coerce.string().nonempty().optional()
}

export const paramsSchema = {
  id: z.coerce.number().positive().min(1)
}
