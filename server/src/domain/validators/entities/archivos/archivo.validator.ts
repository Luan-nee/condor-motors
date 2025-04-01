/* eslint-disable @typescript-eslint/no-unsafe-type-assertion */
import z from 'zod'
import { Validator } from '@/domain/validators/validator'
import { fileTypeValues } from '@/consts'
import type { FileTypeValues } from '@/types/zod'

const createArchivoSchema = z.object({
  nombre: z
    .string()
    .trim()
    .min(2)
    .max(255)
    .refine((val) => Validator.isValidDescription(val), {
      message:
        'La descripción solo puede contener este set de caracteres: a-zA-Z0-9áéíóúñüÁÉÍÓÚÑÜ.,¡!¿?-()[]{}$%&*\'_"@#+'
    }),
  tipo: z
    .string()
    .trim()
    .refine(
      (value) => {
        if (Object.values(fileTypeValues).includes(value as FileTypeValues)) {
          return true
        }
      },
      {
        message:
          'El tipo de archivo es inválido solo se permiten estos tipos (apk | desktop-app)'
      }
    ),
  visible: z.boolean().default(false)
})

export const createArchivoValidator = (object: unknown) =>
  createArchivoSchema.safeParse(object)
