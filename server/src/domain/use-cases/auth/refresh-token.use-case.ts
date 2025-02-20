import { cuentasEmpleadosTable } from '@/db/schema'
import type { RefreshTokenCookieDto } from '@/domain/dtos/auth/refresh-token-cookie.dto'
import type { TokenAuthenticator } from '@/interfaces'
import { db } from '@db/connection'
import { CustomError } from '@domain/errors/custom.error'
import { AuthPayloadMapper } from '@domain/mappers/auth-payload.mapper'
import { eq } from 'drizzle-orm'

export class RefreshToken {
  constructor(private readonly tokenAuthenticator: TokenAuthenticator) {}
  private readonly invalidTokenError = CustomError.unauthorized(
    'Invalid refresh token'
  )

  private readonly getUser = async (
    refreshTokenCookieDto: RefreshTokenCookieDto
  ) => {
    try {
      const data = this.tokenAuthenticator.decode({
        token: refreshTokenCookieDto.refreshToken
      })

      if (data === null || typeof data === 'string' || data.id === undefined) {
        throw this.invalidTokenError
      }

      const users = await db
        .select()
        .from(cuentasEmpleadosTable)
        .where(eq(cuentasEmpleadosTable.id, data.id))

      if (users.length <= 0) {
        throw this.invalidTokenError
      }

      const [user] = users

      return user
    } catch (error) {
      throw this.invalidTokenError
    }
  }

  async execute(refreshTokenCookieDto: RefreshTokenCookieDto) {
    const user = await this.getUser(refreshTokenCookieDto)

    try {
      this.tokenAuthenticator.verify({
        token: refreshTokenCookieDto.refreshToken,
        secret: user.secret
      })
    } catch (error) {
      throw this.invalidTokenError
    }

    const payload = AuthPayloadMapper.authPayloadFromObject(user)

    const accessToken = this.tokenAuthenticator.generateAccessToken({
      payload
    })

    return {
      accessToken,
      data: {
        id: payload.id
      }
    }
  }
}
