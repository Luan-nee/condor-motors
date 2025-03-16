import { JwtAdapter } from '@/config/jwt'
import { CustomResponse } from '@/core/responses/custom.response'
import { authPayloadValidator } from '@/domain/validators/auth/auth-payload.validator'
import type { NextFunction, Request, Response } from 'express'
import { JsonWebTokenError } from 'jsonwebtoken'

export class AuthMiddleware {
  static readonly requests = (
    req: Request,
    res: Response,
    next: NextFunction
  ) => {
    const { headers } = req
    const { authorization: authHeader } = headers

    if (authHeader === undefined || typeof authHeader !== 'string') {
      CustomResponse.invalidAccessToken({ res })
      return
    }

    const parts = authHeader.split(' ')

    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      CustomResponse.invalidAccessToken({ res })
      return
    }

    const [, token] = parts

    try {
      const decodedAuthPayload = JwtAdapter.verify({ token })

      const result = authPayloadValidator(decodedAuthPayload)

      if (!result.success) {
        CustomResponse.invalidAccessToken({ res })
        return
      }

      const { data: authPayload } = result

      req.authPayload = authPayload

      next()
    } catch (error) {
      if (error instanceof JsonWebTokenError) {
        CustomResponse.invalidAccessToken({ res })
      }

      next(error)
    }
  }
}
