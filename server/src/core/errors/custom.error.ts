import { responseStatus } from '@/consts'
import type { ResponseStatusType } from '@/types/core'

interface CustomErrorConstructor {
  statusCode: number
  message: string
  status: ResponseStatusType
  data?: any
  redirect?: string
}

export class CustomError extends Error {
  public readonly statusCode: number
  public readonly message: string
  public readonly status: ResponseStatusType
  public readonly data?: any
  public readonly redirect?: string

  constructor({
    statusCode,
    message,
    status,
    data,
    redirect
  }: CustomErrorConstructor) {
    super(message)

    this.statusCode = statusCode
    this.message = message
    this.status = status
    this.data = data
    this.redirect = redirect
  }

  static badRequest(message: string) {
    return new CustomError({
      statusCode: 400,
      message,
      status: responseStatus.fail
    })
  }

  static unauthorized(message: string, redirect: string) {
    return new CustomError({
      statusCode: 401,
      message,
      status: responseStatus.fail,
      redirect
    })
  }

  static forbidden(
    message = 'No tienes los suficientes permisos para realizar esta acción'
  ) {
    return new CustomError({
      statusCode: 403,
      message,
      status: responseStatus.fail
    })
  }

  static notFound(message = 'Not found') {
    return new CustomError({
      statusCode: 404,
      message,
      status: responseStatus.fail
    })
  }

  static conflict(message: string) {
    return new CustomError({
      statusCode: 409,
      message,
      status: responseStatus.fail
    })
  }

  static unprocessableEntity(message: string) {
    return new CustomError({
      statusCode: 422,
      message,
      status: responseStatus.fail
    })
  }

  static tooManyRequests(message: string) {
    return new CustomError({
      statusCode: 429,
      message,
      status: responseStatus.error
    })
  }

  static internalServer(message = 'Unexpected error') {
    return new CustomError({
      statusCode: 500,
      message,
      status: responseStatus.error
    })
  }

  static notImplemented(message = 'Not implemented') {
    return new CustomError({
      statusCode: 501,
      message,
      status: responseStatus.error
    })
  }

  static badGateway(message: string) {
    return new CustomError({
      statusCode: 502,
      message,
      status: responseStatus.error
    })
  }

  static serviceUnavailable(message: string) {
    return new CustomError({
      statusCode: 503,
      message,
      status: responseStatus.error
    })
  }

  static corsError(message = 'Not allowed by CORS', allowedOrigins: string[]) {
    return new CustomError({
      statusCode: 403,
      message,
      status: responseStatus.fail,
      data: {
        allowedOrigins
      }
    })
  }
}
