import { refreshTokenCookieName } from '@/consts'
import { RefreshTokenCookieDto } from '@/domain/dtos/auth/refresh-token-cookie.dto'
import { RefreshToken } from '@/domain/use-cases/auth/refresh-token.use-case'
import type {
  AuthSerializer,
  Encryptor,
  TokenAuthenticator
} from '@/types/interfaces'
import { LoginUserDto } from '@domain/dtos/auth/login-user.dto'
import { RegisterUserDto } from '@domain/dtos/auth/register-user.dto'
import { handleError } from '@domain/errors/handle.error'
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
    const [error, registerUserDto] = RegisterUserDto.create(req.body)
    if (error !== undefined || registerUserDto === undefined) {
      res.status(400).json({ error: JSON.parse(error ?? '') })
      return
    }

    const registerUser = new RegisterUser(
      this.tokenAuthenticator,
      this.encryptor
    )

    registerUser
      .execute(registerUserDto)
      .then((user) => {
        const serializedTokens = this.authSerializer.refreshAccessToken({
          accessToken: user.accessToken,
          refreshToken: user.refreshToken
        })

        res
          .status(200)
          .setHeader('Set-Cookie', serializedTokens.refresTokenCookie)
          .header('Authorization', serializedTokens.bearerAccessToken)
          .json(user.data)
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }

  loginUser = (req: Request, res: Response) => {
    const [error, loginUserDto] = LoginUserDto.create(req.body)
    if (error !== undefined || loginUserDto === undefined) {
      res
        .status(400)
        .json({ error: 'Nombre de usuario o contraseña incorrectos' })
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

        res
          .status(200)
          .setHeader('Set-Cookie', serializedTokens.refresTokenCookie)
          .header('Authorization', serializedTokens.bearerAccessToken)
          .json(user.data)
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
      res.status(401).json({ error })
      return
    }

    const refreshToken = new RefreshToken(this.tokenAuthenticator)

    refreshToken
      .execute(refreshTokenCookieDto)
      .then((user) => {
        const bearerAccessToken = this.authSerializer.bearerAccessToken({
          accessToken: user.accessToken
        })

        res
          .status(200)
          .header('Authorization', bearerAccessToken)
          .json(user.data)
      })
      .catch((error: unknown) => {
        res.clearCookie(refreshTokenCookieName)
        handleError(error, res)
      })
  }

  // authorize = (req: Request, res: Response) => {}
}
