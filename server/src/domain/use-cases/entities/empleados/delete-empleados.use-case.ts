import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { empleadosTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { eq } from 'drizzle-orm'

export class DeleteEmpleado {
  async execute(numericIdDto: NumericIdDto) {
    const empleados = await db
      .delete(empleadosTable)
      .where(eq(empleadosTable.id, numericIdDto.id))
      .returning({ id: empleadosTable.id })
    if (empleados.length <= 0) {
      throw CustomError.badRequest(
        `No se pudo eliminar la sucursal con el id '${numericIdDto.id}' (No encontrada)`
      )
    }
    const [empleado] = empleados
    return empleado
  }
}
