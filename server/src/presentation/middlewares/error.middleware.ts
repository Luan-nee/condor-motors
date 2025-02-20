import { CustomError } from '@domain/errors/custom.error'
import { handleError } from '@domain/errors/handle.error'
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
      const jsonError = new CustomError(400, 'Invalid JSON format')
      handleError(jsonError, res)
      return
    }

    handleError(error, res)
  }
}
