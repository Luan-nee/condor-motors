import { z } from 'zod'

const isValidSku = (str: string) =>
  /^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ0-9\s.\-_/\\]+$/.test(str)

const isValidNombre = (str: string) =>
  /^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ0-9\s\-_]+$/.test(str)

export const productoSchema = {
  sku: z
    .string()
    .min(2)
    .max(255)
    .refine((val) => isValidSku(val), {
      message:
        'El sku del producto solo puede contener números, espacios, puntos, guiones, barras diagonales y letras (mayúsculas o minúsculas)'
    }),
  nombre: z
    .string()
    .min(2)
    .max(255)
    .refine((val) => isValidNombre(val), {
      message:
        'El nombre del producto solo puede contener números, espacios, guiones y letras (mayúsculas o minúsculas)'
    }),
  descripcion: z.string().min(2).max(1023).optional(),
  maxDiasSinReabastecer: z.number().positive().optional(),
  unidadId: z.number().positive(),
  categoriaId: z.number().positive(),
  marcaId: z.number().positive(),
  precioBase: z.number().min(0).optional(),
  precioMayorista: z.number().min(0).optional(),
  precioOferta: z.number().min(0).optional(),
  stock: z.number().min(0).default(0).optional()
}
