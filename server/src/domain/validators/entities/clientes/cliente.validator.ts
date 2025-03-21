import z from 'zod'
import { ClienteSchema } from './cliente.schema'

const createClienteSchema = z.object({
  tipoDocumentoId: ClienteSchema.tipoDocumentoId,
  numeroDocumento: ClienteSchema.numeroDocumento,
  denominacion: ClienteSchema.denominacion,
  codigoPais: ClienteSchema.codigoPais,
  direccion: ClienteSchema.direccion,
  correo: ClienteSchema.correo,
  telefono: ClienteSchema.telefono
})

export const createClienteValidator = (object: unknown) =>
  createClienteSchema.safeParse(object)
