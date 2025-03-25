import z from 'zod'
import { ReservasProductoSchema } from './reservasProducto.schema'

const createReservasProductosSchema = z.object({
  descripcion: ReservasProductoSchema.descripcion,
  detallesReserva: ReservasProductoSchema.detallesReserva,
  montoAdelantado: ReservasProductoSchema.montoAdelantado,
  fechaRecojo: ReservasProductoSchema.fechaRecojo,
  clienteId: ReservasProductoSchema.clienteId,
  sucursalId: ReservasProductoSchema.sucursalId
})

export const CreateReservasProductoValidator = (object: unknown) =>
  createReservasProductosSchema.safeParse(object)

export const updateReservasProductosValidator = (object: unknown) =>
  createReservasProductosSchema.partial().safeParse(object)
