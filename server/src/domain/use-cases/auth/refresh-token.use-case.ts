import { CustomError } from '@/core/errors/custom.error'
import { cuentasEmpleadosTable, rolesTable } from '@/db/schema'
import type { RefreshTokenCookieDto } from '@/domain/dtos/auth/refresh-token-cookie.dto'
import type { TokenAuthenticator } from '@/types/interfaces'
import { db } from '@db/connection'
import { AuthPayloadMapper } from '@domain/mappers/auth-payload.mapper'
import { eq } from 'drizzle-orm'

interface SelectedFields {
  id: number
  usuario: string
  secret: string
  rol: {
    codigo: string
    nombre: string
  }
}

interface MappedUser {
  id: number
  usuario: string
  rol: {
    codigo: string
    nombre: string
  }
}

export class RefreshToken {
  constructor(private readonly tokenAuthenticator: TokenAuthenticator) {}
  private readonly invalidTokenError = CustomError.unauthorized(
    'Invalid refresh token'
  )
  private readonly selectFields = {
    id: cuentasEmpleadosTable.id,
    usuario: cuentasEmpleadosTable.usuario,
    secret: cuentasEmpleadosTable.secret,
    rol: {
      codigo: rolesTable.codigo,
      nombre: rolesTable.nombre
    }
  }

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
        .select(this.selectFields)
        .from(cuentasEmpleadosTable)
        .innerJoin(rolesTable, eq(cuentasEmpleadosTable.rolId, rolesTable.id))
        .where(eq(cuentasEmpleadosTable.id, data.id))

      if (users.length <= 0) {
        throw this.invalidTokenError
      }

      const [user] = users

      return user
    } catch {
      throw this.invalidTokenError
    }
  }

  private mapUser(input: SelectedFields): MappedUser {
    return {
      id: input.id,
      usuario: input.usuario,
      rol: {
        codigo: input.rol.codigo,
        nombre: input.rol.nombre
      }
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
      user: this.mapUser(user)
    }
  }
}
