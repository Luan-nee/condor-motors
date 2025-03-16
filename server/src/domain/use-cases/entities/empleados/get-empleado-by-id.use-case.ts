import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { empleadosTable, sucursalesTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq } from 'drizzle-orm'

export class GetEmpleadoById {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.empleados.getAny
  private readonly permissionRelated = permissionCodes.empleados.getRelated
  private readonly selectFields = {
    id: empleadosTable.id,
    nombre: empleadosTable.nombre,
    apellidos: empleadosTable.apellidos,
    activo: empleadosTable.activo,
    dni: empleadosTable.dni,
    pathFoto: empleadosTable.pathFoto,
    celular: empleadosTable.celular,
    horaInicioJornada: empleadosTable.horaInicioJornada,
    horaFinJornada: empleadosTable.horaFinJornada,
    fechaContratacion: empleadosTable.fechaContratacion,
    sueldo: empleadosTable.sueldo,
    sucursalId: empleadosTable.sucursalId
  }

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async getRelated(
    numericIdDto: NumericIdDto,
    sucursalId: SucursalIdType
  ) {
    return await db
      .select(this.selectFields)
      .from(empleadosTable)
      .innerJoin(
        sucursalesTable,
        eq(sucursalesTable.id, empleadosTable.sucursalId)
      )
      .where(
        and(
          eq(empleadosTable.id, numericIdDto.id),
          eq(sucursalesTable.id, sucursalId)
        )
      )
  }

  private async getAny(numericIdDto: NumericIdDto) {
    return await db
      .select(this.selectFields)
      .from(empleadosTable)
      .where(eq(empleadosTable.id, numericIdDto.id))
  }

  private async getEmpleado(
    numericIdDto: NumericIdDto,
    hasPermissionAny: boolean,
    sucursalId: SucursalIdType
  ) {
    const empleados = hasPermissionAny
      ? await this.getAny(numericIdDto)
      : await this.getRelated(numericIdDto, sucursalId)

    if (empleados.length <= 0) {
      if (!hasPermissionAny) {
        throw CustomError.forbidden()
      }

      throw CustomError.badRequest(
        `No se encontró ninguna sucursal con el id '${numericIdDto.id}'`
      )
    }

    const [empleado] = empleados

    return empleado
  }

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny, this.permissionRelated]
    )

    const hasPermissionAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionAny
    )

    if (
      !hasPermissionAny &&
      !validPermissions.some(
        (permission) => permission.codigoPermiso === this.permissionRelated
      )
    ) {
      throw CustomError.forbidden()
    }

    const [permission] = validPermissions

    return { hasPermissionAny, sucursalId: permission.sucursalId }
  }

  async execute(numericIdDto: NumericIdDto) {
    const { hasPermissionAny, sucursalId } = await this.validatePermissions()

    const empleado = await this.getEmpleado(
      numericIdDto,
      hasPermissionAny,
      sucursalId
    )

    return empleado
  }
}
