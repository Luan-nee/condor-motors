import { CustomError } from '@domain/errors/custom.error'

export class AuthPayloadMapper {
  static authPayloadFromObject(input: any): AuthPayload {
    const { id } = input

    if (id === undefined) throw CustomError.badRequest('Missing id')

    return {
      id
    }
  }
}
