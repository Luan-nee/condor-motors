import { responseStatus } from '@/consts'
import type { ResponseStatusType } from '@/types/core'

export class CustomError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly message: string,
    public readonly status: ResponseStatusType,
    public readonly data?: any
  ) {
    super(message)
  }

  static badRequest(message: string) {
    return new CustomError(400, message, responseStatus.fail)
  }

  static unauthorized(message: string) {
    return new CustomError(401, message, responseStatus.fail)
  }

  static forbidden(
    message = 'No tienes los suficientes permisos para realizar esta acción'
  ) {
    return new CustomError(403, message, responseStatus.fail)
  }

  static notFound(message = 'Not found') {
    return new CustomError(404, message, responseStatus.fail)
  }

  static conflict(message: string) {
    return new CustomError(409, message, responseStatus.fail)
  }

  static unprocessableEntity(message: string) {
    return new CustomError(422, message, responseStatus.fail)
  }

  static tooManyRequests(message: string) {
    return new CustomError(429, message, responseStatus.error)
  }

  static internalServer(message = 'Unexpected error') {
    return new CustomError(500, message, responseStatus.error)
  }

  static notImplemented(message = 'Not implemented') {
    return new CustomError(501, message, responseStatus.error)
  }

  static serviceUnavailable(message: string) {
    return new CustomError(503, message, responseStatus.error)
  }

  static corsError(message = 'Not allowed by CORS', allowedOrigins: string[]) {
    return new CustomError(403, message, responseStatus.fail, {
      allowedOrigins
    })
  }
}
