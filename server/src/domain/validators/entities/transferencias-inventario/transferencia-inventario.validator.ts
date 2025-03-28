import z from 'zod'
import { transferenciaInvSchema } from '@/domain/validators/entities/transferencias-inventario/transferencia-inventario.schema'

const createTransferenciaInvSchema = z.object({
  sucursalDestinoId: transferenciaInvSchema.sucursalDestinoId,
  items: transferenciaInvSchema.items
})

export const createTransferenciaInvValidator = (object: unknown) =>
  createTransferenciaInvSchema.safeParse(object)
