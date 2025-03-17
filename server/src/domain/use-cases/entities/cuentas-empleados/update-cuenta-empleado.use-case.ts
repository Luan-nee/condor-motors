import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { cuentasEmpleadosTable, rolesCuentasEmpleadosTable } from '@/db/schema'
import type { UpdateCuentaEmpleadoDto } from '@/domain/dtos/entities/cuentas-empleados/update-cuenta-empleado.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { Encryptor, TokenAuthenticator } from '@/types/interfaces'
import { eq, ilike } from 'drizzle-orm'

export class UpdateCuentaEmpleado {
  private readonly tokenAuthenticator: TokenAuthenticator
  private readonly encryptor: Encryptor
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.cuentasEmpleados.updateAny
  private readonly permissionSelf = permissionCodes.cuentasEmpleados.updateSelf

  constructor(
    tokenAuthenticator: TokenAuthenticator,
    encryptor: Encryptor,
    authPayload: AuthPayload
  ) {
    this.tokenAuthenticator = tokenAuthenticator
    this.encryptor = encryptor
    this.authPayload = authPayload
  }

  private async updateCuentaEmpleado(
    updateCuentaEmpleadoDto: UpdateCuentaEmpleadoDto,
    numericIdDto: NumericIdDto
  ) {
    if (updateCuentaEmpleadoDto.usuario !== undefined) {
      const usersWithSameName = await db
        .select({ id: cuentasEmpleadosTable.id })
        .from(cuentasEmpleadosTable)
        .where(
          ilike(cuentasEmpleadosTable.usuario, updateCuentaEmpleadoDto.usuario)
        )

      if (usersWithSameName.length > 0) {
        throw CustomError.badRequest(
          `El nombre de usuario '${updateCuentaEmpleadoDto.usuario}' ya está ocupado`
        )
      }
    }

    if (updateCuentaEmpleadoDto.rolCuentaEmpleadoId !== undefined) {
      const roles = await db
        .select({
          id: rolesCuentasEmpleadosTable.id,
          codigo: rolesCuentasEmpleadosTable.codigo
        })
        .from(rolesCuentasEmpleadosTable)
        .where(
          eq(
            rolesCuentasEmpleadosTable.id,
            updateCuentaEmpleadoDto.rolCuentaEmpleadoId
          )
        )

      if (roles.length <= 0) {
        throw CustomError.badRequest('El rol que intentó asignar no existe')
      }
    }

    const hashedPassword =
      updateCuentaEmpleadoDto.clave !== undefined
        ? await this.encryptor.hash(updateCuentaEmpleadoDto.clave)
        : undefined

    const secret =
      updateCuentaEmpleadoDto.clave !== undefined
        ? this.tokenAuthenticator.randomSecret()
        : undefined

    const now = new Date()

    const updatedResults = await db
      .update(cuentasEmpleadosTable)
      .set({
        usuario: updateCuentaEmpleadoDto.usuario,
        clave: hashedPassword,
        secret,
        rolCuentaEmpleadoId: updateCuentaEmpleadoDto.rolCuentaEmpleadoId,
        fechaActualizacion: now
      })
      .where(eq(cuentasEmpleadosTable.id, numericIdDto.id))
      .returning({ id: cuentasEmpleadosTable.id })

    if (updatedResults.length < 1) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar actualizar los datos de la cuenta'
      )
    }

    const [cuentaEmpleado] = updatedResults

    return cuentaEmpleado
  }

  private async validatePermissions(
    updateCuentaEmpleadoDto: UpdateCuentaEmpleadoDto,
    numericIdDto: NumericIdDto
  ) {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny, this.permissionSelf]
    )

    const hasPermissionAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionAny
    )

    if (hasPermissionAny) {
      if (
        this.authPayload.id === numericIdDto.id &&
        updateCuentaEmpleadoDto.rolCuentaEmpleadoId !== undefined
      ) {
        throw CustomError.forbidden()
      }

      return
    }

    const hasPermissionSelf = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionSelf
    )

    if (
      !hasPermissionSelf ||
      this.authPayload.id !== numericIdDto.id ||
      updateCuentaEmpleadoDto.rolCuentaEmpleadoId !== undefined
    ) {
      throw CustomError.forbidden()
    }
  }

  async execute(
    updateCuentaEmpleadoDto: UpdateCuentaEmpleadoDto,
    numericIdDto: NumericIdDto
  ) {
    await this.validatePermissions(updateCuentaEmpleadoDto, numericIdDto)

    const cuentaEmpleado = await this.updateCuentaEmpleado(
      updateCuentaEmpleadoDto,
      numericIdDto
    )

    return cuentaEmpleado
  }
}
