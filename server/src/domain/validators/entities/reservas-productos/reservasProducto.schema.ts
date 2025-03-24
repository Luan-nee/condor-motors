import z from 'zod'

export const ReservasProductoSchema = {
  descripcion: z.string().trim().min(2),
  detallesReserva: z.string(),
  montoAdelantado: z.number().positive(),
  fechaRecojo: z.string().date(),
  clienteId: z
    .number()
    .positive({ message: 'El numero ingresado no es un ID' }),
  sucursalId: z.number().positive({ message: 'El Id ingresado no es valido' })
}
