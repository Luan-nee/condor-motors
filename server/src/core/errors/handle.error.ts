import { responseStatus } from '@/consts'
import { CustomError } from '@/core/errors/custom.error'
import type { Response } from 'express'
import { CustomResponse } from '../responses/custom.response'

export const handleError = (error: unknown, res: Response) => {
  if (error instanceof CustomError && error.statusCode !== 500) {
    CustomResponse.send({
      res,
      statusCode: error.statusCode,
      status: error.status,
      error: error.message,
      data: error.data
    })
    return
  }

  // eslint-disable-next-line no-console
  console.error(error)
  CustomResponse.send({
    res,
    statusCode: 500,
    status: responseStatus.error,
    error: 'Internal Server Error'
  })
}
