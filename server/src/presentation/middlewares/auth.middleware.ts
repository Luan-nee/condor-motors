import { JwtAdapter } from '@/config/jwt'
import { CustomResponse } from '@/core/responses/custom.response'
import { authPayloadValidator } from '@/domain/validators/auth/auth-payload.validator'
import type { NextFunction, Request, Response } from 'express'
import { JsonWebTokenError } from 'jsonwebtoken'

export class AuthMiddleware {
  private static handleAuthError(res: Response) {
    CustomResponse.unauthorized({
      res,
      error: 'Invalid or missing authorization token'
    })
  }

  static readonly requests = (
    req: Request,
    res: Response,
    next: NextFunction
  ) => {
    const {
      headers: { authorization: authHeader }
    } = req

    if (authHeader === undefined || typeof authHeader !== 'string') {
      AuthMiddleware.handleAuthError(res)
      return
    }

    const parts = authHeader.split(' ')

    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      AuthMiddleware.handleAuthError(res)
      return
    }

    const [, token] = parts

    try {
      const decodedAuthPayload = JwtAdapter.verify({ token })

      const validationResult = authPayloadValidator(decodedAuthPayload)

      if (!validationResult.success) {
        AuthMiddleware.handleAuthError(res)
        return
      }

      const { data: authPayload } = validationResult

      req.authPayload = authPayload

      next()
    } catch (error) {
      if (error instanceof JsonWebTokenError) {
        AuthMiddleware.handleAuthError(res)
        return
      }

      next(error)
    }
  }
}
