import { db } from '@/db/connection'
import { cuentasEmpleadosTable } from '@/db/schema'
import type { LoginUserDto } from '@/domain/dtos/auth/login-user.dto'
import { CustomError } from '@/domain/errors/custom.error'
import type { Encryptor, TokenAuthenticator } from '@/domain/interfaces'
import { AuthPayloadMapper } from '@/domain/mappers/auth-payload.mapper'
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

    return {
      id: user.id,
      usuario: user.usuario,
      fechaRegistro: user.fechaRegistro,
      rolCuentaEmpleadoId: user.rolCuentaEmpleadoId,
      empleadoId: user.empleadoId
    }
  }

  async execute(loginUserDto: LoginUserDto) {
    const user = await this.login(loginUserDto)

    const payload = AuthPayloadMapper.authPayloadFromObject(user)

    const token = this.tokenAuthenticator.generateToken(payload, '2h')

    if (typeof token !== 'string') {
      throw CustomError.internalServer('Error generating token')
    }

    return {
      token,
      user: {
        id: user.id,
        usuario: user.usuario,
        fechaRegistro: user.fechaRegistro,
        rolCuentaEmpleadoId: user.rolCuentaEmpleadoId,
        empleadoId: user.empleadoId
      }
    }
  }
}
