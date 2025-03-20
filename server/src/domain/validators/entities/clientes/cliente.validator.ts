import z from 'zod'
import { ClienteSchema } from './cliente.schema'

const createClienteSchema = z.object({
  nombresApellidos: ClienteSchema.nombresApellidos,
  dni: ClienteSchema.dni,
  razonSocial: ClienteSchema.razonSocial,
  ruc: ClienteSchema.ruc,
  telefono: ClienteSchema.telefono,
  correo: ClienteSchema.correo,
  tipoPersonaId: ClienteSchema.tipoPersonaId
})

export const createClienteValidator = (object: unknown) =>
  createClienteSchema.safeParse(object)
