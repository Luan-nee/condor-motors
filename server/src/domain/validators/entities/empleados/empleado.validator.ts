import { empleadoSchema } from '@/domain/validators/entities/empleados/empleado.schema'
import { z } from 'zod'

const createEmpleadoSchema = z.object({
  nombre: empleadoSchema.nombre,
  apellidos: empleadoSchema.apellidos,
  activo: empleadoSchema.activo,
  dni: empleadoSchema.dni,
  celular: empleadoSchema.celular,
  horaInicioJornada: empleadoSchema.horaInicioJornada,
  horaFinJornada: empleadoSchema.horaFinJornada,
  fechaContratacion: empleadoSchema.fechaContratacion,
  sueldo: empleadoSchema.sueldo,
  sucursalId: empleadoSchema.sucursalId
})

export const createEmpleadoValidator = (object: unknown) =>
  createEmpleadoSchema.safeParse(object)

export const updateEmpleadoValidator = (object: unknown) =>
  createEmpleadoSchema.partial().safeParse(object)
