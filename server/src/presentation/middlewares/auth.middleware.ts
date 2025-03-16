import { JwtAdapter } from '@/config/jwt'
import { CustomError } from '@/core/errors/custom.error'
import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { authPayloadValidator } from '@/domain/validators/auth/auth-payload.validator'
import type { NextFunction, Request, Response } from 'express'

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
        throw CustomError.unauthorized('Access token inválido')
      }

      const { data: authPayload } = result

      req.authPayload = authPayload
    } catch (error) {
      handleError(error, res)
    }

    next()
  }
}
