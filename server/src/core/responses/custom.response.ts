import { responseStatus } from '@/consts'
import type {
  AcceptedArgs,
  CreatedArgs,
  ErrorResponseArgs,
  NoContentArgs,
  SendResponseArgs,
  SuccessArgs
} from '@/types/core'

export class CustomResponse {
  static send({
    res,
    message,
    data,
    pagination,
    metadata,
    status = responseStatus.success,
    statusCode = 200,
    error,
    cookie,
    authorization
  }: SendResponseArgs) {
    const response = {
      status,
      message,
      data,
      pagination,
      metadata,
      error
    }

    if (cookie !== undefined) {
      res.setHeader('Set-Cookie', cookie)
    }

    if (authorization !== undefined) {
      res.header('Authorization', authorization)
    }

    if (typeof response.data === 'string') {
      try {
        response.data = JSON.parse(data)
      } catch (error) {}
    }

    if (typeof response.error === 'string') {
      try {
        response.error = JSON.parse(error)
      } catch (error) {}
    }

    res.status(statusCode).json(response)
  }

  static success({
    res,
    message,
    data,
    pagination,
    metadata,
    cookie,
    authorization
  }: SuccessArgs) {
    this.send({
      res,
      data,
      message,
      status: responseStatus.success,
      statusCode: 200,
      pagination,
      metadata,
      cookie,
      authorization
    })
  }

  static created({ res, message, data }: CreatedArgs) {
    this.send({
      res,
      data,
      message,
      status: responseStatus.success,
      statusCode: 201
    })
  }

  static accepted({ res, message, data }: AcceptedArgs) {
    this.send({
      res,
      data,
      message,
      status: responseStatus.success,
      statusCode: 202
    })
  }

  static noContent({ res, message }: NoContentArgs) {
    this.send({
      res,
      message,
      status: responseStatus.success,
      statusCode: 204
    })
  }

  static badRequest({ res, error }: ErrorResponseArgs) {
    this.send({
      res,
      error,
      status: responseStatus.fail,
      statusCode: 400
    })
  }

  static unauthorized({ res, error }: ErrorResponseArgs) {
    this.send({
      res,
      error,
      status: responseStatus.fail,
      statusCode: 401
    })
  }

  static invalidAccessToken({ res }: ErrorResponseArgs) {
    this.send({
      res,
      error: 'Access token inválido',
      status: responseStatus.fail,
      statusCode: 401
    })
  }

  static notFound({ res }: ErrorResponseArgs) {
    this.send({
      res,
      error: 'Not found',
      status: responseStatus.fail,
      statusCode: 404
    })
  }

  static notImplemented({ res }: ErrorResponseArgs) {
    this.send({
      res,
      error: 'Not implemented',
      status: responseStatus.error,
      statusCode: 501
    })
  }
}
