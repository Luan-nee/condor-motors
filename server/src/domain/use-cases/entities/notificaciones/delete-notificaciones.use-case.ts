import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { notificacionesTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { eq } from 'drizzle-orm'

export class DeleteNotificacion {
  async execute(numericIdDto: NumericIdDto) {
    const notificacion = await db
      .delete(notificacionesTable)
      .where(eq(notificacionesTable.id, numericIdDto.id))
      .returning({ id: notificacionesTable.id })
    if (notificacion.length <= 0) {
      throw CustomError.badRequest(
        `No se pudo eliminar la Notificacion ${numericIdDto.id}`
      )
    }
    const [notificaciones] = notificacion

    return notificaciones
  }
}
