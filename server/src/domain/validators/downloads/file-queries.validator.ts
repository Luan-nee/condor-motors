import z from 'zod'

const FileQueriesSchema = z.object({
  exp: z.coerce.number().positive(),
  tk: z.string().trim().length(32)
})

export const fileQueriesValidator = (object: unknown) =>
  FileQueriesSchema.safeParse(object)
