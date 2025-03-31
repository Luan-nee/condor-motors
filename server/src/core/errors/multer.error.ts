import type { Response } from 'express'
import type { MulterError } from 'multer'
import { CustomResponse } from '@/core/responses/custom.response'

const buildErrorResponse = (error: MulterError, message: string) => ({
  message,
  description: error.message,
  field: error.field
})

export const handleMulterError = (error: MulterError, res: Response) => {
  if (error.code === 'LIMIT_PART_COUNT') {
    CustomResponse.badRequest({
      res,
      error: buildErrorResponse(error, 'Too many parts')
    })
    return
  }
  if (error.code === 'LIMIT_FILE_SIZE') {
    CustomResponse.badRequest({
      res,
      error: buildErrorResponse(error, 'File too large')
    })
    return
  }
  if (error.code === 'LIMIT_FILE_COUNT') {
    CustomResponse.badRequest({
      res,
      error: buildErrorResponse(error, 'Too many files')
    })
    return
  }
  if (error.code === 'LIMIT_FIELD_KEY') {
    CustomResponse.badRequest({
      res,
      error: buildErrorResponse(error, 'Field name too long')
    })
    return
  }
  if (error.code === 'LIMIT_FIELD_VALUE') {
    CustomResponse.badRequest({
      res,
      error: buildErrorResponse(error, 'Field value too long')
    })
    return
  }
  if (error.code === 'LIMIT_FIELD_COUNT') {
    CustomResponse.badRequest({
      res,
      error: buildErrorResponse(error, 'Too many fields')
    })
    return
  }
  if ((error.code as string) === 'LIMIT_UNEXPECTED_FILE') {
    CustomResponse.badRequest({
      res,
      error: buildErrorResponse(error, 'Unexpected file')
    })
    return
  }

  CustomResponse.internalServer({ res })
}
