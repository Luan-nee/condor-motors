import z from 'zod'
import { clienteSchema } from '@/domain/validators/entities/clientes/cliente.schema'

const createClienteSchema = z.object({
  tipoDocumentoId: clienteSchema.tipoDocumentoId,
  numeroDocumento: clienteSchema.numeroDocumento,
  denominacion: clienteSchema.denominacion,
  direccion: clienteSchema.direccion,
  correo: clienteSchema.correo,
  telefono: clienteSchema.telefono
})

export const createClienteValidator = (object: unknown) =>
  createClienteSchema.safeParse(object)

const updateClienteSchema = z.object({
  numeroDocumento: clienteSchema.numeroDocumento,
  denominacion: clienteSchema.denominacion,
  direccion: clienteSchema.direccion,
  correo: clienteSchema.correo,
  telefono: clienteSchema.telefono
})

export const updateClienteValidator = (object: unknown) =>
  updateClienteSchema.partial().safeParse(object)
