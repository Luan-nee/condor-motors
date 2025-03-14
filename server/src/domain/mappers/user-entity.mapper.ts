import type { UserEntity } from '@/types/schemas'

export class UserEntityMapper {
  static userEntityFromObject(input: UserEntity) {
    const parsedId = String(input.id)
    const parsedRolCuentaEmpleadoId = String(input.rolCuentaEmpleadoId)
    const parsedEmpleadoId = String(input.empleadoId)

    return {
      id: parsedId,
      usuario: input.usuario,
      rolCuentaEmpleadoId: parsedRolCuentaEmpleadoId,
      rolCuentaEmpleadoCodigo: input.rolCuentaEmpleadoCodigo,
      empleadoId: parsedEmpleadoId,
      fechaCreacion: input.fechaCreacion,
      fechaActualizacion: input.fechaActualizacion,
      sucursal: input.sucursal,
      sucursalId: input.sucursalId
    }
  }
}
