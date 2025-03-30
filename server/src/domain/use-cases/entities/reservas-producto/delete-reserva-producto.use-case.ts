import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { reservasProductosTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { eq } from 'drizzle-orm'

export class DeleteReservasProductos {
  async execute(numericIdDto: NumericIdDto) {
    const eliminando = await db
      .delete(reservasProductosTable)
      .where(eq(reservasProductosTable.id, numericIdDto.id))
      .returning({ id: reservasProductosTable.id })

    if (eliminando.length <= 0) {
      throw CustomError.badRequest(
        `No se pudo eliminar la reserva con el ID  ${numericIdDto.id}`
      )
    }
    const [reserva] = eliminando

    return reserva
  }
}
