import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { UserEntityMapper } from '@/domain/mappers/user-entity.mapper'
import type { Encryptor, TokenAuthenticator } from '@/types/interfaces'
import { db } from '@db/connection'
import {
  cuentasEmpleadosTable,
  empleadosTable,
  rolesCuentasEmpleadosTable,
  sucursalesTable
} from '@db/schema'
import type { RegisterUserDto } from '@domain/dtos/auth/register-user.dto'
import { AuthPayloadMapper } from '@domain/mappers/auth-payload.mapper'
import { and, eq, ilike, notExists } from 'drizzle-orm'

export class RegisterUser {
  private readonly permissionAny = permissionCodes.cuentasEmpleados.createAny
  constructor(
    private readonly tokenAuthenticator: TokenAuthenticator,
    private readonly encryptor: Encryptor,
    private readonly authPayload: AuthPayload
  ) {}

  private readonly register = async (registerUserDto: RegisterUserDto) => {
    const usersWithSameName = await db
      .select({ id: cuentasEmpleadosTable.id })
      .from(cuentasEmpleadosTable)
      .where(ilike(cuentasEmpleadosTable.usuario, registerUserDto.usuario))

    if (usersWithSameName.length > 0) {
      throw CustomError.badRequest(
        `El nombre de usuario '${registerUserDto.usuario}' ya está ocupado`
      )
    }

    const empleados = await db
      .select({
        id: empleadosTable.id,
        nombreSucursal: sucursalesTable.nombre,
        sucursalId: sucursalesTable.id
      })
      .from(empleadosTable)
      .innerJoin(
        sucursalesTable,
        eq(sucursalesTable.id, empleadosTable.sucursalId)
      )
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

    const [empleado] = empleados

    const roles = await db
      .select({
        id: rolesCuentasEmpleadosTable.id,
        codigo: rolesCuentasEmpleadosTable.codigo
      })
      .from(rolesCuentasEmpleadosTable)
      .where(
        eq(rolesCuentasEmpleadosTable.id, registerUserDto.rolCuentaEmpleadoId)
      )

    if (roles.length <= 0) {
      throw CustomError.badRequest('El rol que intentó asignar no existe')
    }

    const hashedPassword = await this.encryptor.hash(registerUserDto.clave)
    const secret = this.tokenAuthenticator.randomSecret()

    const insertUserResult = await db
      .insert(cuentasEmpleadosTable)
      .values({
        usuario: registerUserDto.usuario,
        clave: hashedPassword,
        secret,
        rolCuentaEmpleadoId: registerUserDto.rolCuentaEmpleadoId,
        empleadoId: registerUserDto.empleadoId
      })
      .returning()

    if (insertUserResult.length <= 0) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar crear el usuario'
      )
    }

    const [selectedRol] = roles

    const [user] = insertUserResult

    return {
      ...user,
      rolCuentaEmpleadoCodigo: selectedRol.codigo,
      sucursal: empleado.nombreSucursal,
      sucursalId: empleado.sucursalId
    }
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

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny]
    )

    const hasPermissionCreateAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionAny
    )

    if (!hasPermissionCreateAny) {
      throw CustomError.forbidden()
    }
  }

  async execute(registerUserDto: RegisterUserDto) {
    await this.validatePermissions()

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
