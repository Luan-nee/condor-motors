import { proformaVentaSchema } from '@domain/validators/entities/proformas-venta/proforma-venta.schema'
import z from 'zod'

const createProformaVentaSchema = z.object({
  nombre: proformaVentaSchema.nombre,
  empleadoId: proformaVentaSchema.empleadoId,
  detalles: proformaVentaSchema.detalles
})

export const createProformaVentaValidator = (object: unknown) =>
  createProformaVentaSchema.safeParse(object)
