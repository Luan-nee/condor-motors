import { z } from 'zod'

export const sucursalSchema = {
  nombre: z
    .string({
      message: 'El nombre de la sucursal debe ser de tipo string'
    })
    .min(2)
    .max(255)
    .refine((val) => /^[a-zA-Z0-9ñÑáéíóúÁÉÍÓÚ\s_-]{1,255}$/.test(val), {
      message:
        'El nombre de la sucursal debe solo puede contener números, espacios, guiones y letras (mayúsculas o minúsculas)'
    }),
  ubicacion: z
    .string({
      message: 'La ubicación de la sucursal debe ser de tipo string'
    })
    .min(2)
    .max(255)
    .refine((val) => /^[a-zA-Z0-9ñÑáéíóúÁÉÍÓÚ\s_-]{1,255}$/.test(val), {
      message:
        'La ubicación de la sucursal debe solo puede contener números, espacios, guiones y letras (mayúsculas o minúsculas)'
    })
    .optional(),
  sucursalCentral: z.boolean({
    message: 'La propiedad "sucursalCentral" debe ser de tipo booleano'
  })
}
