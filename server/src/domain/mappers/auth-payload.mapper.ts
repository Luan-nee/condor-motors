import { CustomError } from '@domain/errors/custom.error'

export class AuthPayloadMapper {
  static authPayloadFromObject(input: any): AuthPayload {
    const { id, rolCuentaEmpleadoId, empleadoId } = input

    if (id === undefined) throw CustomError.badRequest('Missing id')
    if (rolCuentaEmpleadoId === undefined) {
      throw CustomError.badRequest('Missing username')
    }
    if (empleadoId === undefined) throw CustomError.badRequest('Missing email')

    return {
      id,
      rolCuentaEmpleadoId,
      empleadoId
    }
  }
}
