import { ventaSchema } from '@domain/validators/entities/ventas/venta.schema'
import z from 'zod'

const createVentaSchema = z.object({
  observaciones: ventaSchema.observaciones,
  tipoDocumentoId: ventaSchema.tipoDocumentoId,
  detalles: ventaSchema.detalles,
  monedaId: ventaSchema.monedaId,
  metodoPagoId: ventaSchema.metodoPagoId,
  clienteId: ventaSchema.clienteId,
  empleadoId: ventaSchema.empleadoId,
  fechaEmision: ventaSchema.fechaEmision,
  horaEmision: ventaSchema.horaEmision
})

export const createVentaValidator = (object: unknown) =>
  createVentaSchema.safeParse(object)
