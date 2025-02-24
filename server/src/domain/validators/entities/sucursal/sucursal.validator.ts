import { sucursalSchema } from '@/domain/validators/entities/sucursal/sucursal.schema'
import { z } from 'zod'

const createSucursalSchema = z.object({
  nombre: sucursalSchema.nombre,
  direccion: sucursalSchema.direccion,
  sucursalCentral: sucursalSchema.sucursalCentral
})

export const createSucursalValidator = (object: unknown) =>
  createSucursalSchema.safeParse(object)

const updateSucursalSchema = z.object({
  nombre: sucursalSchema.nombre,
  direccion: sucursalSchema.direccion,
  sucursalCentral: sucursalSchema.sucursalCentral
})

export const updateSucursalValidator = (object: unknown) =>
  updateSucursalSchema.partial().safeParse(object)
