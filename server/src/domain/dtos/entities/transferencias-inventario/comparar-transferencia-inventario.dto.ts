import { z } from 'zod'

const compararTransferenciaInvSchema = z.object({
  sucursalOrigenId: z.number().int().positive()
})

export type CompararTransferenciaInvDto = z.infer<
  typeof compararTransferenciaInvSchema
>

export class CompararTransferenciaInvDtoValidator {
  static create(
    props: Record<string, unknown>
  ): readonly [string[] | undefined, CompararTransferenciaInvDto | undefined] {
    const result = compararTransferenciaInvSchema.safeParse(props)

    if (!result.success) {
      const {
        error: { errors }
      } = result
      const messages = errors.map((error) => error.message)
      return [messages, undefined] as const
    }

    return [undefined, result.data] as const
  }
}
