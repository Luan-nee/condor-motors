import { UserEntityMapper } from '@/domain/mappers/user-entity.mapper'
import type { Encryptor, TokenAuthenticator } from '@/types/interfaces'
import { db } from '@db/connection'
import { cuentasEmpleadosTable, empleadosTable } from '@db/schema'
import type { RegisterUserDto } from '@domain/dtos/auth/register-user.dto'
import { CustomError } from '@domain/errors/custom.error'
import { AuthPayloadMapper } from '@domain/mappers/auth-payload.mapper'
import { and, eq, notExists, sql } from 'drizzle-orm'

export class RegisterUser {
  constructor(
    private readonly tokenAuthenticator: TokenAuthenticator,
    private readonly encryptor: Encryptor
  ) {}

  private readonly register = async (registerUserDto: RegisterUserDto) => {
    const usersWithSameName = await db
      .select()
      .from(cuentasEmpleadosTable)
      .where(
        sql`lower(${cuentasEmpleadosTable.usuario}) = lower(${registerUserDto.usuario})`
      )

    if (usersWithSameName.length > 0) {
      throw CustomError.badRequest(
        `El nombre de usuario '${registerUserDto.usuario}' ya está ocupado`
      )
    }

    const empleados = await db
      .select()
      .from(empleadosTable)
      .where(
        and(
          eq(empleadosTable.id, registerUserDto.empleadoId),
          notExists(
            db
              .select()
              .from(cuentasEmpleadosTable)
              .where(eq(cuentasEmpleadosTable.empleadoId, empleadosTable.id))
          )
        )
      )

    if (empleados.length <= 0) {
      throw CustomError.badRequest(
        'El empleado no existe o ya tiene una cuenta asociada'
      )
    }

    const hashedPassword = await this.encryptor.hash(registerUserDto.clave)
    const secret = this.tokenAuthenticator.randomSecret()

    const insertUserResult = await db
      .insert(cuentasEmpleadosTable)
      .values({
        usuario: registerUserDto.usuario,
        clave: hashedPassword,
        secret,
        fechaRegistro: new Date(),
        rolCuentaEmpleadoId: registerUserDto.rolCuentaEmpleadoId,
        empleadoId: registerUserDto.empleadoId
      })
      .returning()

    if (insertUserResult.length <= 0) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar crear el usuario'
      )
    }

    const [user] = insertUserResult

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

  async execute(
    registerUserDto: RegisterUserDto
  ): Promise<UserEntityWithTokens> {
    const user = await this.register(registerUserDto)
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
