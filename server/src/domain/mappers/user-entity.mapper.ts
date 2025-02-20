import { CustomError } from '@domain/errors/custom.error'

export class UserEntityMapper {
  static userEntityFromObject(input: ObjectAny): UserEntity {
    const { id, usuario, fechaRegistro, rolCuentaEmpleadoId, empleadoId } =
      input

    if (id === undefined) {
      throw CustomError.badRequest('Missing id')
    }
    if (usuario === undefined) {
      throw CustomError.badRequest('Missing usuario')
    }
    if (fechaRegistro === undefined) {
      throw CustomError.badRequest('Missing fechaRegistro')
    }
    if (rolCuentaEmpleadoId === undefined) {
      throw CustomError.badRequest('Missing rolCuentaEmpleadoId')
    }
    if (empleadoId === undefined) {
      throw CustomError.badRequest('Missing empleadoId')
    }

    return {
      id,
      usuario,
      fechaRegistro,
      rolCuentaEmpleadoId,
      empleadoId
    }
  }
}
