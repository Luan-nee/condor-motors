import { responseStatus } from '@/consts'
import type {
  AcceptedArgs,
  CreatedArgs,
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
      error
    }

    if (cookie !== undefined) {
      res.setHeader('Set-Cookie', cookie)
    }

    if (authorization !== undefined) {
      res.header('Authorization', authorization)
    }

    res.status(statusCode).json(response)
  }

  static success({
    res,
    message,
    data,
    pagination,
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
}
