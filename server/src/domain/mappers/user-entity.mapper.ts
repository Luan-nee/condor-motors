import type { UserEntity } from '@/types/schemas'
import { CustomError } from '@domain/errors/custom.error'

export class UserEntityMapper {
  static userEntityFromObject(input: any): UserEntity {
    const {
      id,
      usuario,
      rolCuentaEmpleadoId,
      empleadoId,
      fechaCreacion,
      fechaActualizacion
    } = input

    if (id === undefined) {
      throw CustomError.badRequest('Missing id')
    }
    if (usuario === undefined) {
      throw CustomError.badRequest('Missing usuario')
    }
    if (rolCuentaEmpleadoId === undefined) {
      throw CustomError.badRequest('Missing rolCuentaEmpleadoId')
    }
    if (empleadoId === undefined) {
      throw CustomError.badRequest('Missing empleadoId')
    }
    if (fechaCreacion === undefined) {
      throw CustomError.badRequest('Missing fechaCreacion')
    }
    if (fechaActualizacion === undefined) {
      throw CustomError.badRequest('Missing fechaActualizacion')
    }

    return {
      id,
      usuario,
      rolCuentaEmpleadoId,
      empleadoId,
      fechaCreacion,
      fechaActualizacion
    }
  }
}
