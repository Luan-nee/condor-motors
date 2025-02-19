import { db } from '@db/connection'
import { cuentasEmpleadosTable, empleadosTable } from '@db/schema'
import type { RegisterUserDto } from '@domain/dtos/auth/register-user.dto'
import { CustomError } from '@domain/errors/custom.error'
import type { Encryptor, TokenAuthenticator } from '@domain/interfaces'
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

    const [insertedUser] = await db
      .insert(cuentasEmpleadosTable)
      .values({
        usuario: registerUserDto.usuario,
        clave: hashedPassword,
        fechaRegistro: new Date(),
        rolCuentaEmpleadoId: registerUserDto.rolCuentaEmpleadoId,
        empleadoId: registerUserDto.empleadoId
      })
      .returning()

    return insertedUser
  }

  async execute(registerUserDto: RegisterUserDto) {
    const user = await this.register(registerUserDto)

    const payload = AuthPayloadMapper.authPayloadFromObject(user)

    const token = this.tokenAuthenticator.generateAccessToken(payload)

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
