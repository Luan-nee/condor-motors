import { CustomError } from '@/core/errors/custom.error'
import { handleError } from '@/core/errors/handle.error'
import type { NextFunction, Request, Response } from 'express'

export class ErrorMiddleware {
  static requests = (
    error: Error,
    _req: Request,
    res: Response,
    _next: NextFunction
  ) => {
    if (
      error instanceof SyntaxError &&
      'body' in error &&
      error.message.includes('JSON')
    ) {
      const jsonError = CustomError.badRequest('Invalid JSON format')
      handleError(jsonError, res)
      return
    }

    handleError(error, res)
  }
}
