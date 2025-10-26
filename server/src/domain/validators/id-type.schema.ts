import z from 'zod'

export const idTypeBaseSchema = {
  numericId: z.coerce.number().positive(),
  uuid: z.uuid()
}
