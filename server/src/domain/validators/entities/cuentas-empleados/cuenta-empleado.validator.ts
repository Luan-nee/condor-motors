import { cuentaEmpleadoSchema } from '@/domain/validators/entities/cuentas-empleados/cuenta-empleado.schema'
import { z } from 'zod'

const UpdateCuentaEmpleadoSchema = z.object({
  usuario: cuentaEmpleadoSchema.usuario,
  clave: cuentaEmpleadoSchema.clave,
  rolCuentaEmpleadoId: cuentaEmpleadoSchema.rolCuentaEmpleadoId
})

export const updateCuentaEmpleadoValidator = (object: unknown) =>
  UpdateCuentaEmpleadoSchema.partial().safeParse(object)
