// import { permissionCodes } from '@/consts'
import { CustomError } from '@/core/errors/custom.error'
import { empleadosTable, sucursalesTable } from '@/db/schema'
import type { CreateEmpleadoDto } from '@/domain/dtos/entities/empleados/create-empleado.dto'
import { EmpleadoEntityMapper } from '@/domain/mappers/empleado-entity.mapper'
import { db } from '@db/connection'
import { eq } from 'drizzle-orm'

export class CreateEmpleado {
  // private readonly authPayload: AuthPayload
  // private readonly permissionCreateAny = permissionCodes.empleados

  // constructor(authPayload: AuthPayload) {
  //   this.authPayload = authPayload
  // }

  async execute(createEmpleadoDto: CreateEmpleadoDto) {
    const results = await db
      .select({
        empleadoId: empleadosTable.id,
        sucursalId: sucursalesTable.id
      })
      .from(sucursalesTable)
      .leftJoin(empleadosTable, eq(empleadosTable.dni, createEmpleadoDto.dni))
      .where(eq(sucursalesTable.id, createEmpleadoDto.sucursalId))

    if (results.length < 1) {
      throw CustomError.badRequest('La sucursal ingresada no existe')
    }

    const [result] = results

    if (result.empleadoId != null) {
      throw CustomError.badRequest(
        `Ya existe un empleado con ese dni: ${createEmpleadoDto.dni}`
      )
    }

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
      .returning()

    if (insertedEmpleadoResult.length < 1) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar registrar el empleado'
      )
    }

    const [empleado] = insertedEmpleadoResult

    const mappedEmpleado = EmpleadoEntityMapper.fromObject(empleado)

    return mappedEmpleado
  }
}
