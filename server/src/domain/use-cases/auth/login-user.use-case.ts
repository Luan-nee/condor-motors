import { CustomError } from '@/core/errors/custom.error'
import { UserEntityMapper } from '@/domain/mappers/user-entity.mapper'
import type { Encryptor, TokenAuthenticator } from '@/types/interfaces'
import type { UserEntityWithTokens } from '@/types/schemas'
import { db } from '@db/connection'
import { cuentasEmpleadosTable } from '@db/schema'
import type { LoginUserDto } from '@domain/dtos/auth/login-user.dto'
import { AuthPayloadMapper } from '@domain/mappers/auth-payload.mapper'
import { like } from 'drizzle-orm'

export class LoginUser {
  constructor(
    private readonly tokenAuthenticator: TokenAuthenticator,
    private readonly encryptor: Encryptor
  ) {}

  private readonly login = async (loginUserDto: LoginUserDto) => {
    const users = await db
      .select()
      .from(cuentasEmpleadosTable)
      .where(like(cuentasEmpleadosTable.usuario, loginUserDto.usuario))

    if (users.length <= 0) {
      throw CustomError.badRequest('Nombre de usuario o contraseña incorrectos')
    }

    const [user] = users

    const isMatch = await this.encryptor.compare(loginUserDto.clave, user.clave)

    if (!isMatch) {
      throw CustomError.badRequest('Nombre de usuario o contraseña incorrectos')
    }

    return user
  }

  private readonly generateTokens = (payload: AuthPayload, secret: string) => {
    const refreshToken = this.tokenAuthenticator.generateRefreshToken({
      payload,
      secret
    })

    const accessToken = this.tokenAuthenticator.generateAccessToken({ payload })

    if (
      typeof refreshToken.token !== 'string' ||
      typeof accessToken !== 'string'
    ) {
      throw CustomError.internalServer(
        `Error generating token for user with id: ${payload.id} `
      )
    }
    return {
      accessToken,
      refreshToken: refreshToken.token
    }
  }

  async execute(loginUserDto: LoginUserDto): Promise<UserEntityWithTokens> {
    const user = await this.login(loginUserDto)
    const payload = AuthPayloadMapper.authPayloadFromObject(user)

    const { accessToken, refreshToken } = this.generateTokens(
      payload,
      user.secret
    )

    const mappedUser = UserEntityMapper.userEntityFromObject(user)

    return {
      accessToken,
      refreshToken,
      data: mappedUser
    }
  }
}
