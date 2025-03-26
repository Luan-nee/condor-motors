import { CustomError } from '@/core/errors/custom.error'
import { UserEntityMapper } from '@/domain/mappers/user-entity.mapper'
import type { Encryptor, TokenAuthenticator } from '@/types/interfaces'
import { db } from '@db/connection'
import {
  cuentasEmpleadosTable,
  empleadosTable,
  rolesTable,
  sucursalesTable
} from '@db/schema'
import type { LoginUserDto } from '@domain/dtos/auth/login-user.dto'
import { AuthPayloadMapper } from '@domain/mappers/auth-payload.mapper'
import { eq, like } from 'drizzle-orm'

export class LoginUser {
  private readonly selectFields = {
    id: cuentasEmpleadosTable.id,
    usuario: cuentasEmpleadosTable.usuario,
    clave: cuentasEmpleadosTable.clave,
    secret: cuentasEmpleadosTable.secret,
    rolCuentaEmpleadoId: cuentasEmpleadosTable.rolId,
    rolCuentaEmpleadoCodigo: rolesTable.codigo,
    empleadoId: cuentasEmpleadosTable.empleadoId,
    fechaCreacion: cuentasEmpleadosTable.fechaCreacion,
    fechaActualizacion: cuentasEmpleadosTable.fechaActualizacion,
    sucursal: sucursalesTable.nombre,
    sucursalId: sucursalesTable.id
  }

  constructor(
    private readonly tokenAuthenticator: TokenAuthenticator,
    private readonly encryptor: Encryptor
  ) {}

  private readonly login = async (loginUserDto: LoginUserDto) => {
    const users = await db
      .select(this.selectFields)
      .from(cuentasEmpleadosTable)
      .innerJoin(rolesTable, eq(rolesTable.id, cuentasEmpleadosTable.rolId))
      .innerJoin(
        empleadosTable,
        eq(empleadosTable.id, cuentasEmpleadosTable.empleadoId)
      )
      .innerJoin(
        sucursalesTable,
        eq(sucursalesTable.id, empleadosTable.sucursalId)
      )
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

  async execute(loginUserDto: LoginUserDto) {
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
