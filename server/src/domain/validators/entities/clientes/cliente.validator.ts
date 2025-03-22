import z from 'zod'
import { ClienteSchema } from './cliente.schema'

const createClienteSchema = z.object({
  tipoDocumentoId: ClienteSchema.tipoDocumentoId,
  numeroDocumento: ClienteSchema.numeroDocumento,
  denominacion: ClienteSchema.denominacion,
  direccion: ClienteSchema.direccion,
  correo: ClienteSchema.correo,
  telefono: ClienteSchema.telefono
})

export const createClienteValidator = (object: unknown) =>
  createClienteSchema.safeParse(object)

const updateClienteSchema = z.object({
  denominacion: ClienteSchema.denominacion,
  direccion: ClienteSchema.direccion,
  correo: ClienteSchema.correo,
  telefono: ClienteSchema.telefono
})

export const updateClienteValidator = (object: unknown) =>
  updateClienteSchema.partial().safeParse(object)
