import { facturacionSchema } from '@domain/validators/entities/facturacion/facturacion.schema'
import z from 'zod'

const declareVentaSchema = z.object({
  enviarCliente: facturacionSchema.enviarCliente,
  ventaId: facturacionSchema.ventaId
})

export const declareVentaValidator = (object: unknown) =>
  declareVentaSchema.safeParse(object)

const syncDocumentSchema = z.object({
  ventaId: facturacionSchema.ventaId
})

export const syncDocumentValidator = (object: unknown) =>
  syncDocumentSchema.safeParse(object)
