import { z } from 'astro/zod'
import { Validator } from './validator'

const uploadFileSchema = z.object({
  nombre: z.coerce
    .string()
    .trim()
    .min(2, {
      message: 'El nombre debe contener al menos 2 caracteres'
    })
    .max(255, {
      message: 'El nombre no puede contener más de 255 caracteres'
    })
    .refine((val) => Validator.isValidDescription(val), {
      message:
        'El nombre solo puede contener este set de caracteres: a-zA-Z0-9áéíóúñüÁÉÍÓÚÑÜ.,¡!¿?-()[]{}$%&*\'_"@#+'
    }),
  visible: z.coerce.boolean().default(false)
})

export const uploadFileValidator = (input: unknown) => {
  const result = uploadFileSchema.safeParse(input)

  if (!result.success) {
    const errors = result.error.format()

    const fields = ['nombre', 'visible'] as const

    try {
      for (const field of fields) {
        if (errors[field] != null) {
          const message = errors[field]?._errors[0]

          return {
            error: { message }
          }
        }
      }

      return { error: { message: 'Unexpected error' } }
    } catch {
      return { error: { message: 'Unexpected error' } }
    }
  }

  return { data: result.data }
}
