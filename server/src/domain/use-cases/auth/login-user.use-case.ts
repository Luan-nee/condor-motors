import { UserEntityMapper } from '@/domain/mappers/user-entity.mapper'
import type { Encryptor, TokenAuthenticator } from '@/interfaces'
import { db } from '@db/connection'
import { cuentasEmpleadosTable } from '@db/schema'
import type { LoginUserDto } from '@domain/dtos/auth/login-user.dto'
import { CustomError } from '@domain/errors/custom.error'
import { AuthPayloadMapper } from '@domain/mappers/auth-payload.mapper'
import { eq } from 'drizzle-orm'

export class LoginUser {
  constructor(
    private readonly tokenAuthenticator: TokenAuthenticator,
    private readonly encryptor: Encryptor
  ) {}

  private readonly login = async (loginUserDto: LoginUserDto) => {
    const users = await db
      .select()
      .from(cuentasEmpleadosTable)
      .where(eq(cuentasEmpleadosTable.usuario, loginUserDto.usuario))

    if (users.length <= 0 || typeof loginUserDto.clave !== 'string') {
      // throw CustomError.badRequest('Nombre de usuario o contraseña incorrectos')
      throw CustomError.badRequest('Usuario no encontrado')
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
      throw CustomError.internalServer('Error generating token')
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
      user: mappedUser
    }
  }
}
