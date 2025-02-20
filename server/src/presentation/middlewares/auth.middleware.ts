import { JwtAdapter } from '@/config/jwt'
import { CustomError } from '@/domain/errors/custom.error'
import { handleError } from '@/domain/errors/handle.error'
import type { NextFunction, Request, Response } from 'express'

export class AuthMiddleware {
  static requests = (req: Request, res: Response, next: NextFunction) => {
    const invalidTokenError = CustomError.unauthorized('Access token inválido')

    try {
      const {
        headers: { authorization: authHeader }
      } = req

      if (authHeader === undefined || typeof authHeader !== 'string') {
        throw invalidTokenError
      }

      const parts = authHeader.split(' ')

      if (parts.length !== 2 || parts[0] !== 'Bearer') {
        throw invalidTokenError
      }

      const [, token] = parts

      try {
        JwtAdapter.verify({ token })
      } catch (error) {
        throw invalidTokenError
      }

      next()
    } catch (error) {
      handleError(error, res)
    }
  }
}
