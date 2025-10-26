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
      const { error } = result
      const validationErrors = z.treeifyError(error)

      return [validationErrors.errors, undefined] as const
    }

    return [undefined, result.data] as const
  }
}
