import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { reservasProductosTable } from '@/db/schema'
import type { UpdateReservasProductosDto } from '@/domain/dtos/entities/reservas-producto/update-reservasProductos.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { count, eq } from 'drizzle-orm'

export class UpdateReservasProductos {
  private async updateReservasProductos(
    updateReservasProductosDto: UpdateReservasProductosDto,
    numericIdDto: NumericIdDto
  ) {
    const reserva = await db
      .select({ count: count(reservasProductosTable.id) })
      .from(reservasProductosTable)
      .where(eq(reservasProductosTable.id, numericIdDto.id))

    if (Number(reserva) === 0) {
      throw CustomError.badRequest(
        `No se encontro ninguna reservacion con el ID : ${numericIdDto.id}`
      )
    }

    const now = new Date()

    const updateReservaResult = await db
      .update(reservasProductosTable)
      .set({
        descripcion: updateReservasProductosDto.descripcion,
        detallesReserva: updateReservasProductosDto.detallesReserva,
        montoAdelantado: updateReservasProductosDto.montoAdelantado?.toFixed(2),
        fechaRecojo: updateReservasProductosDto.fechaRecojo,
        sucursalId: updateReservasProductosDto.sucursalId,
        fechaActualizacion: now
      })
      .where(eq(reservasProductosTable.id, numericIdDto.id))
      .returning({ id: reservasProductosTable.id })

    if (updateReservaResult.length < 1) {
      throw CustomError.internalServer(
        'ocurrio un error al mandar la actualizacion'
      )
    }

    const [reservas] = updateReservaResult
    return reservas
  }

  async execute(
    updateReservasProductosDto: UpdateReservasProductosDto,
    numericIdDto: NumericIdDto
  ) {
    const reserva = await this.updateReservasProductos(
      updateReservasProductosDto,
      numericIdDto
    )
    return reserva
  }
}
