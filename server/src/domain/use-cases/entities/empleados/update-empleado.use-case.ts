import { CustomError } from '@/core/errors/custom.error'
import { empleadosTable } from '@/db/schema'
import type { UpdateEmpleadoDto } from '@/domain/dtos/entities/empleados/ubdate-empleado.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { EmpleadoEntityMapper } from '@/domain/mappers/empleado-entity.mapper'
import { db } from '@db/connection'
import { eq, ilike } from 'drizzle-orm'

export class UpdateEmpleado {
  async execute(
    updateEmpleadoDto: UpdateEmpleadoDto,
    numericIdDto: NumericIdDto
  ) {
    const empleados = await db
      .select()
      .from(empleadosTable)
      .where(eq(empleadosTable.id, numericIdDto.id))

    if (empleados.length <= 0) {
      throw CustomError.badRequest(
        `No se encontró ningun empleado con el id '${numericIdDto.id}'`
      )
    }

    if (updateEmpleadoDto.dni !== undefined) {
      const empleadoWithSameName = await db
        .select()
        .from(empleadosTable)
        .where(ilike(empleadosTable.dni, updateEmpleadoDto.dni))

      if (empleadoWithSameName.length > 0) {
        throw CustomError.badRequest(
          `Ya existe una sucursal con ese nombre: '${updateEmpleadoDto.dni}'`
        )
      }
    }

    const updateEmpleadoResultado = await db
      .update(empleadosTable)
      .set({
        nombre: updateEmpleadoDto.nombre,
        apellidos: updateEmpleadoDto.apellido,
        edad: updateEmpleadoDto.edad,
        dni: updateEmpleadoDto.dni,
        horaInicioJornada: updateEmpleadoDto.horaInicioJornada,
        horaFinJornada: updateEmpleadoDto.horaFinJornada,
        sueldo: String(updateEmpleadoDto.sueldo),
        sucursalId: updateEmpleadoDto.sucursalId
      })
      .where(eq(empleadosTable.id, numericIdDto.id))
      .returning()

    if (updateEmpleadoResultado.length <= 0) {
      throw CustomError.internalServer(
        'Ocurrio un error al actualizar los datos , asegurese de enviar los datos correctamente'
      )
    }
    const [empleado] = updateEmpleadoResultado

    const MappedEmpleado = EmpleadoEntityMapper.fromObject(empleado)

    return MappedEmpleado
  }
}
