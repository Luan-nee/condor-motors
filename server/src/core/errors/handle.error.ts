import { CustomError } from '@/core/errors/custom.error'
import type { Response } from 'express'
import { CustomResponse } from '@/core/responses/custom.response'
import { MulterError } from 'multer'
import { handleMulterError } from '@/core/errors/multer.error'
import { logger } from '@/config/logger'

export const handleError = (error: unknown, res: Response) => {
  if (error instanceof CustomError && error.statusCode !== 500) {
    CustomResponse.send({
      res,
      statusCode: error.statusCode,
      status: error.status,
      error: error.message,
      data: error.data,
      redirect: error.redirect
    })
    return
  }

  if (error instanceof MulterError) {
    logger.error({
      message: 'Unexpected Multer error',
      context: { error }
    })
    handleMulterError(error, res)
    return
  }

  logger.error({
    message: 'Unexpected Server error',
    context: { error }
  })
  CustomResponse.internalServer({ res })
}
