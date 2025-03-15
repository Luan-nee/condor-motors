import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { empleadosTable, proformasVentaTable, ventasTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { eq, count } from 'drizzle-orm'

export class DeleteEmpleado {
  async hasRelationData(valorId: number): Promise<boolean> {
    let valorRetorno = false
    const ventasRelacionadas = await db
      .select({ count: count() })
      .from(ventasTable)
      .where(eq(ventasTable.empleadoId, valorId))
    // .execute(
    // sql`SELECT COUNT(*) AS count FROM ventas WHERE empleado_id = ${valorId} `
    // const total = Number(ventasRelacionadas[0])

    const proformasRelacionadas = await db
      .select({ count: count() })
      .from(proformasVentaTable)
      .where(eq(proformasVentaTable.empleadoId, valorId))

    if (
      Number(ventasRelacionadas[0]) > 0 &&
      Number(proformasRelacionadas[0]) > 0
    ) {
      valorRetorno = true
    }
    return valorRetorno
  }

  async execute(numericIdDto: NumericIdDto) {
    const DatosRelatedTables = await this.hasRelationData(numericIdDto.id)
    if (DatosRelatedTables) {
      const empleadoActualizado = await db
        .update(empleadosTable)
        .set({ activo: false })
        .where(eq(empleadosTable.id, numericIdDto.id))
        .returning({ id: empleadosTable.id, activo: empleadosTable.activo })
      if (empleadoActualizado.length <= 0) {
        throw CustomError.badRequest(
          `No se pudo eliminar al empleado  con el id '${numericIdDto.id}' (No encontrado)`
        )
      }
      const [empleadoAc] = empleadoActualizado

      return empleadoAc
    }
    const empleados = await db
      .delete(empleadosTable)
      .where(eq(empleadosTable.id, numericIdDto.id))
      .returning({ id: empleadosTable.id, activo: empleadosTable.activo })
    if (empleados.length <= 0) {
      throw CustomError.badRequest(
        `No se pudo eliminar al empleado  con el id '${numericIdDto.id}' (No encontrado)`
      )
    }
    const [empleado] = empleados
    return empleado
  }
}
