import z from 'zod'
import { transferenciaInventarioSchema } from './transferenciaInventario.schema'

const CreateTransferenciaInventarioSchema = z.object({
  empleadoId: transferenciaInventarioSchema.empleadoId,
  estadoTransferenciaId: transferenciaInventarioSchema.estadoTransferenciaId,
  sucursalOrigenId: transferenciaInventarioSchema.sucursalOrigenId,
  sucursalDestinoId: transferenciaInventarioSchema.sucursalDestinoId,
  detalleVenta: transferenciaInventarioSchema.detalleVenta
})

export const createTransferenciaInventarioValidator = (object: unknown) =>
  CreateTransferenciaInventarioSchema.safeParse(object)
