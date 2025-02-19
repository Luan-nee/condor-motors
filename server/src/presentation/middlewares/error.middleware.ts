import { CustomError } from '@domain/errors/custom.error'
import { handleError } from '@domain/errors/handle.error'
import type { NextFunction, Request, Response } from 'express'

export class ErrorMiddleware {
  static requests = (
    err: Error,
    _req: Request,
    res: Response,
    _next: NextFunction
  ) => {
    if (
      err instanceof SyntaxError &&
      'body' in err &&
      err.message.includes('JSON')
    ) {
      const errorMessage = 'Invalid JSON format'
      const jsonError = new CustomError(400, errorMessage)

      handleError(jsonError, res)
      return
    }

    handleError(err, res)
  }
}
