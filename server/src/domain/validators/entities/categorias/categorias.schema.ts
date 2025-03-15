import { z } from 'zod'

const validacionText = (valor: string) =>
  /^(?! )([a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+(?: [a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+){0,3})$/.test(
    valor
  )
export const categoriasSchema = {
  nombre: z
    .string()
    .min(3)
    .max(100)
    .refine((val) => validacionText(val), {
      message: 'El nombre de la categoria no puede contener solo espacios'
    }),
  descripcion: z
    .string()
    .min(5)
    .max(255)
    .refine((val) => validacionText(val), {
      message: 'la descripcion de la categoria no puede contener solo espacios'
    })
}
