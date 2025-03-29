import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { empleadosTable, sucursalesTable } from '@/db/schema'
import type { CreateEmpleadoDto } from '@/domain/dtos/entities/empleados/create-empleado.dto'
import { db } from '@db/connection'
import { eq } from 'drizzle-orm'

export class CreateEmpleado {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.empleados.createAny

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async validateRelated(createEmpleadoDto: CreateEmpleadoDto) {
    const results = await db
      .select({
        empleadoId: empleadosTable.id
      })
      .from(sucursalesTable)
      .where(eq(sucursalesTable.id, createEmpleadoDto.sucursalId))

    if (results.length < 1) {
      throw CustomError.badRequest('La sucursal ingresada no existe')
    }
  }

  private async createEmpleado(createEmpleadoDto: CreateEmpleadoDto) {
    await this.validateRelated(createEmpleadoDto)

    const sueldoString =
      createEmpleadoDto.sueldo === undefined
        ? undefined
        : createEmpleadoDto.sueldo.toFixed(2)

    const insertedEmpleadoResult = await db
      .insert(empleadosTable)
      .values({
        nombre: createEmpleadoDto.nombre,
        apellidos: createEmpleadoDto.apellidos,
        activo: createEmpleadoDto.activo,
        dni: createEmpleadoDto.dni,
        // pathFoto: createEmpleadoDto.pathFoto,
        celular: createEmpleadoDto.celular,
        horaInicioJornada: createEmpleadoDto.horaInicioJornada,
        horaFinJornada: createEmpleadoDto.horaFinJornada,
        fechaContratacion: createEmpleadoDto.fechaContratacion,
        sueldo: sueldoString,
        sucursalId: createEmpleadoDto.sucursalId
      })
      .returning({ id: empleadosTable.id, pathFoto: empleadosTable.pathFoto })

    if (insertedEmpleadoResult.length < 1) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar registrar el empleado'
      )
    }

    return insertedEmpleadoResult
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

  async execute(createEmpleadoDto: CreateEmpleadoDto) {
    await this.validatePermissions()

    const empleado = await this.createEmpleado(createEmpleadoDto)

    return empleado
  }
}
