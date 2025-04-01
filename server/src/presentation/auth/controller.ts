import { refreshTokenCookieName } from '@/consts'
import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { RefreshTokenCookieDto } from '@/domain/dtos/auth/refresh-token-cookie.dto'
import { RefreshToken } from '@/domain/use-cases/auth/refresh-token.use-case'
import { TestSession } from '@/domain/use-cases/auth/test-session.use-case'
import type {
  AuthSerializer,
  Encryptor,
  TokenAuthenticator
} from '@/types/interfaces'
import { LoginUserDto } from '@domain/dtos/auth/login-user.dto'
import { RegisterUserDto } from '@domain/dtos/auth/register-user.dto'
import { LoginUser } from '@domain/use-cases/auth/login-user.use-case'
import { RegisterUser } from '@domain/use-cases/auth/register-user.use-case'
import type { Request, Response } from 'express'

export class AuthController {
  constructor(
    private readonly tokenAuthenticator: TokenAuthenticator,
    private readonly encryptor: Encryptor,
    private readonly authSerializer: AuthSerializer
  ) {}

  registerUser = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const [error, registerUserDto] = RegisterUserDto.create(req.body)
    if (error !== undefined || registerUserDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    const { authPayload } = req

    const registerUser = new RegisterUser(
      this.tokenAuthenticator,
      this.encryptor,
      authPayload
    )

    registerUser
      .execute(registerUserDto)
      .then((user) => {
        CustomResponse.success({
          res,
          data: user.data
        })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  loginUser = (req: Request, res: Response) => {
    const [error, loginUserDto] = LoginUserDto.create(req.body)
    if (error !== undefined || loginUserDto === undefined) {
      CustomResponse.badRequest({
        res,
        error: 'Nombre o contraseña incorrectos'
      })
      return
    }

    const loginUser = new LoginUser(this.tokenAuthenticator, this.encryptor)

    loginUser
      .execute(loginUserDto)
      .then((user) => {
        const serializedTokens = this.authSerializer.refreshAccessToken({
          accessToken: user.accessToken,
          refreshToken: user.refreshToken
        })

        CustomResponse.success({
          res,
          data: user.data,
          cookie: serializedTokens.refresTokenCookie,
          authorization: serializedTokens.bearerAccessToken
        })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  refreshToken = (req: Request, res: Response) => {
    const [error, refreshTokenCookieDto] = RefreshTokenCookieDto.create(
      req.cookies
    )

    if (error !== undefined || refreshTokenCookieDto === undefined) {
      CustomResponse.unauthorized({ res, error })
      return
    }

    const refreshToken = new RefreshToken(this.tokenAuthenticator)

    refreshToken
      .execute(refreshTokenCookieDto)
      .then((user) => {
        const bearerAccessToken = this.authSerializer.bearerAccessToken({
          accessToken: user.accessToken
        })

        CustomResponse.success({
          res,
          authorization: bearerAccessToken
        })
      })
      .catch((error: unknown) => {
        res.clearCookie(refreshTokenCookieName)
        handleError(error, res)
      })
  }

  testSession = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const { authPayload } = req

    const testSession = new TestSession(authPayload)

    testSession
      .execute()
      .then((user) => {
        CustomResponse.success({
          res,
          data: user
        })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  logoutUser = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    res.clearCookie(refreshTokenCookieName)

    CustomResponse.success({
      res,
      message: 'Sesión terminada exitosamente'
    })
  }

  // authorize = (req: Request, res: Response) => {}
}
