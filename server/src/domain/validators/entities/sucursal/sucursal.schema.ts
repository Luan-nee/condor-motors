import { z } from 'zod'

const isValidNombre = (str: string) =>
  /^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ0-9\s.\-_]+$/.test(str)

const isValidDireccion = (str: string) =>
  /^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ0-9\s.,\-_]+$/.test(str)

export const sucursalSchema = {
  nombre: z
    .string()
    .min(2)
    .max(255)
    .refine((val) => isValidNombre(val), {
      message:
        'El nombre de la sucursal solo puede contener números, espacios, guiones y letras (mayúsculas o minúsculas)'
    }),
  direccion: z
    .string()
    .min(2)
    .max(255)
    .refine((val) => isValidDireccion(val), {
      message:
        'La dirección de la sucursal solo puede contener números, espacios, puntos, guiones y letras (mayúsculas o minúsculas)'
    })
    .optional(),
  sucursalCentral: z.boolean()
}
