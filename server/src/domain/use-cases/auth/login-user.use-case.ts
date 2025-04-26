import { CustomError } from '@/core/errors/custom.error'
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
    empleado: {
      activo: empleadosTable.activo,
      nombres: empleadosTable.nombre,
      apellidos: empleadosTable.apellidos,
      pathFoto: empleadosTable.pathFoto
    },
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

    if (!user.empleado.activo) {
      throw CustomError.badRequest(
        'Su cuenta de usuario se encuentra desactivada, contacte al administrador para que este habilite su cuenta'
      )
    }

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

    return {
      accessToken,
      refreshToken,
      data: {
        id: user.id,
        usuario: user.usuario,
        rolCuentaEmpleadoId: user.rolCuentaEmpleadoId,
        rolCuentaEmpleadoCodigo: user.rolCuentaEmpleadoCodigo,
        empleadoId: user.empleadoId,
        empleado: {
          activo: user.empleado.activo,
          nombres: user.empleado.nombres,
          apellidos: user.empleado.apellidos,
          pathFoto: user.empleado.pathFoto
        },
        fechaCreacion: user.fechaCreacion,
        fechaActualizacion: user.fechaActualizacion,
        sucursal: user.sucursal,
        sucursalId: user.sucursalId
      }
    }
  }
}
