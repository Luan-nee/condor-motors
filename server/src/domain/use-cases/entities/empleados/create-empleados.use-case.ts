// import { permissionCodes } from '@/consts'
import { CustomError } from '@/core/errors/custom.error'
import { empleadosTable, sucursalesTable } from '@/db/schema'
import type { CreateEmpleadoDto } from '@/domain/dtos/entities/empleados/create-empleados.dto'
import { EmpleadoEntityMapper } from '@/domain/mappers/empleado-entity.mapper'
import { db } from '@db/connection'
import { eq, ilike } from 'drizzle-orm'

export class CreateEmpleado {
  // private readonly authPayload: AuthPayload
  // private readonly permissionCreateAny = permissionCodes.empleados

  // constructor(authPayload: AuthPayload) {
  //   this.authPayload = authPayload
  // }

  async execute(createEmpleadoDto: CreateEmpleadoDto) {
    if (createEmpleadoDto.dni !== undefined) {
      const empleadosWithSameDni = await db
        .select({ id: empleadosTable.id })
        .from(empleadosTable)
        .where(ilike(empleadosTable.dni, createEmpleadoDto.dni))

      if (empleadosWithSameDni.length > 0) {
        throw CustomError.badRequest(
          `Ya existe un empleado con ese dni: ${createEmpleadoDto.dni}`
        )
      }
    }

    const sucursales = await db
      .select({ id: sucursalesTable.id })
      .from(sucursalesTable)
      .where(eq(sucursalesTable.id, createEmpleadoDto.sucursalId))

    if (sucursales.length < 1) {
      throw CustomError.badRequest('La sucursal ingresada no existe')
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
        edad: createEmpleadoDto.edad,
        dni: createEmpleadoDto.dni,
        horaInicioJornada: createEmpleadoDto.horaInicioJornada,
        horaFinJornada: createEmpleadoDto.horaFinJornada,
        fechaContratacion: createEmpleadoDto.fechaContratacion,
        sueldo: sueldoString,
        sucursalId: createEmpleadoDto.sucursalId
      })
      .returning()

    if (insertedEmpleadoResult.length <= 0) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar registrar el empleado'
      )
    }

    const [empleado] = insertedEmpleadoResult

    const mappedEmpleado = EmpleadoEntityMapper.fromObject(empleado)

    return mappedEmpleado
  }
}
