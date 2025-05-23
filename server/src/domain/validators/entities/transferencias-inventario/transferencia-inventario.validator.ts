import z from 'zod'
import { transferenciaInvSchema } from '@/domain/validators/entities/transferencias-inventario/transferencia-inventario.schema'

const createTransferenciaInvSchema = z.object({
  sucursalDestinoId: transferenciaInvSchema.sucursalDestinoId,
  items: transferenciaInvSchema.items
})

export const createTransferenciaInvValidator = (object: unknown) =>
  createTransferenciaInvSchema.safeParse(object)

const enviarTransferenciaInvSchema = z.object({
  sucursalOrigenId: transferenciaInvSchema.sucursalDestinoId
})

export const enviarTransferenciaInvValidator = (object: unknown) =>
  enviarTransferenciaInvSchema.safeParse(object)

const addItemTransferenciaInv = z.object({
  items: transferenciaInvSchema.items
})

export const addItemTransferenciaInvValidator = (object: unknown) =>
  addItemTransferenciaInv.safeParse(object)

const updateItemTransferenciaInv = z.object({
  cantidad: transferenciaInvSchema.cantidad
})

export const updateItemTransferenciaInvValidator = (object: unknown) =>
  updateItemTransferenciaInv.safeParse(object)
