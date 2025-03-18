import { categoriasSchema } from './categorias.schema'
import { z } from 'zod'

const createCategoriaSchema = z.object({
  nombre: categoriasSchema.nombre,
  descripcion: categoriasSchema.descripcion
})

export const createCategoriaValidator = (object: unknown) =>
  createCategoriaSchema.safeParse(object)

export const updateCategoriaValidator = (object: unknown) =>
  createCategoriaSchema.partial().safeParse(object)
