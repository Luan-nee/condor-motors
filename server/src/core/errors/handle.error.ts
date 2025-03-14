import { responseStatus } from '@/consts'
import { CustomError } from '@/core/errors/custom.error'
import type { Response } from 'express'
import { CustomResponse } from '../responses/custom.response'
import { CorsMiddleware } from '@/presentation/middlewares/cors.middleware'

export const handleError = (error: unknown, res: Response) => {
  if (error instanceof CustomError && error.statusCode !== 500) {
    const additionalInfo =
      error instanceof CustomError && error.statusCode === 403
        ? { allowedOrigins: CorsMiddleware.allowedOrigins }
        : undefined

    CustomResponse.send({
      res,
      statusCode: error.statusCode,
      message: error.message,
      status: error.status,
      error: error.message,
      data: additionalInfo
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
