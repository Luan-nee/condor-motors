import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { empleadosTable, sucursalesTable } from '@/db/schema'
import type { UpdateEmpleadoDto } from '@/domain/dtos/entities/empleados/update-empleado.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { db } from '@db/connection'
import { eq, ilike, or } from 'drizzle-orm'

export class UpdateEmpleado {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.empleados.updateAny
  // private readonly permissionSelf = permissionCodes.empleados.updateSelf
  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async updateEmpleado(
    updateEmpleadoDto: UpdateEmpleadoDto,
    numericIdDto: NumericIdDto
  ) {
    const sueldoString =
      updateEmpleadoDto.sueldo === undefined
        ? undefined
        : updateEmpleadoDto.sueldo.toFixed(2)

    const updateEmpleadoResultado = await db
      .update(empleadosTable)
      .set({
        nombre: updateEmpleadoDto.nombre,
        apellidos: updateEmpleadoDto.apellidos,
        activo: updateEmpleadoDto.activo,
        dni: updateEmpleadoDto.dni,
        // pathFoto: updateEmpleadoDto.pathFoto,
        celular: updateEmpleadoDto.celular,
        horaInicioJornada: updateEmpleadoDto.horaInicioJornada,
        horaFinJornada: updateEmpleadoDto.horaFinJornada,
        fechaContratacion: updateEmpleadoDto.fechaContratacion,
        sueldo: sueldoString,
        sucursalId: updateEmpleadoDto.sucursalId
      })
      .where(eq(empleadosTable.id, numericIdDto.id))
      .returning({ id: empleadosTable.id })

    if (updateEmpleadoResultado.length <= 0) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar actualizar los datos del empleado'
      )
    }

    const [empleado] = updateEmpleadoResultado

    return empleado
  }

  private async validateRelacionados(
    updateEmpleadoDto: UpdateEmpleadoDto,
    numericIdDto: NumericIdDto
  ) {
    const whereCondition =
      updateEmpleadoDto.sucursalId !== undefined
        ? eq(sucursalesTable.id, updateEmpleadoDto.sucursalId)
        : undefined

    const results = await db
      .select({
        sucursalId: sucursalesTable.id,
        empleadoId: empleadosTable.id,
        empleadoDni: empleadosTable.dni
      })
      .from(sucursalesTable)
      .leftJoin(
        empleadosTable,
        or(
          eq(empleadosTable.id, numericIdDto.id),
          ilike(
            empleadosTable.dni,
            updateEmpleadoDto.dni ?? 'this-is-not-a-dni'
          )
        )
      )
      .where(whereCondition)

    if (results.length < 1) {
      throw CustomError.badRequest('La sucursal ingresada no existe')
    }

    if (!results.some((result) => result.empleadoId === numericIdDto.id)) {
      throw CustomError.badRequest('El empleado especificado no existe')
    }

    if (updateEmpleadoDto.dni !== undefined) {
      if (
        results.some((result) => result.empleadoDni === updateEmpleadoDto.dni)
      ) {
        throw CustomError.badRequest(
          `Ya existe un empleado con el dni ${updateEmpleadoDto.dni}`
        )
      }
    }
  }

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny]
    )

    const hasPermissionAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionAny
    )

    if (!hasPermissionAny) {
      throw CustomError.forbidden()
    }
  }

  async execute(
    updateEmpleadoDto: UpdateEmpleadoDto,
    numericIdDto: NumericIdDto
  ) {
    await this.validatePermissions()
    await this.validateRelacionados(updateEmpleadoDto, numericIdDto)

    const empleado = await this.updateEmpleado(updateEmpleadoDto, numericIdDto)

    return empleado
  }
}
