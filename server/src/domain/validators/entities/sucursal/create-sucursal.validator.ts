import { sucursalSchema } from '@domain/validators/entities/sucursal/sucursal.validator'
import { z } from 'zod'

const createSucursalSchema = z.object({
  nombre: sucursalSchema.nombre,
  ubicacion: sucursalSchema.ubicacion,
  sucursalCentral: sucursalSchema.sucursalCentral
})

export const createSucursalValidator = (object: unknown) =>
  createSucursalSchema.safeParse(object)
