import { CustomError } from '@domain/errors/custom.error'

export class AuthPayloadMapper {
  static authPayloadFromObject(input: ObjectAny): AuthPayload {
    const { id, rolCuentaEmpleadoId, empleadoId } = input

    if (id === undefined) throw CustomError.badRequest('Missing id')
    if (rolCuentaEmpleadoId === undefined) {
      throw CustomError.badRequest('Missing username')
    }
    if (empleadoId === undefined) {
      throw CustomError.badRequest('Missing empleadoId')
    }

    return {
      id,
      rolCuentaEmpleadoId,
      empleadoId
    }
  }
}
