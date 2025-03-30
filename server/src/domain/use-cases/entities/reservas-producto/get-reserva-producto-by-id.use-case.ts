import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  clientesTable,
  reservasProductosTable,
  sucursalesTable
} from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { eq } from 'drizzle-orm'

export class GetReservasProductoById {
  private readonly selectFields = {
    id: reservasProductosTable.id,
    descripcion: reservasProductosTable.descripcion,
    detallesReserva: reservasProductosTable.detallesReserva,
    montoAdelantado: reservasProductosTable.montoAdelantado,
    fechaRecojo: reservasProductosTable.fechaRecojo,
    denominacion: clientesTable.denominacion,
    clienteId: reservasProductosTable.clienteId,
    sucursalId: reservasProductosTable.sucursalId,
    nombre: sucursalesTable.nombre,
    fechaCreacion: reservasProductosTable.fechaCreacion,
    fechaActualizacion: reservasProductosTable.fechaActualizacion
  }

  private async getRelatedReservasProductos(numericIdDto: NumericIdDto) {
    return await db
      .select(this.selectFields)
      .from(reservasProductosTable)
      .innerJoin(
        clientesTable,
        eq(reservasProductosTable.clienteId, clientesTable.id)
      )
      .innerJoin(
        sucursalesTable,
        eq(reservasProductosTable.sucursalId, sucursalesTable.id)
      )
      .where(eq(reservasProductosTable.id, numericIdDto.id))
  }

  private async getReservaProductoById(numericIdDto: NumericIdDto) {
    const Reserva = await this.getRelatedReservasProductos(numericIdDto)
    if (Reserva.length < 1) {
      throw CustomError.badRequest(
        `No se encontro ninguna reserva con el ID : ${numericIdDto.id}`
      )
    }

    const [ReservaProducto] = Reserva
    return ReservaProducto
  }

  async execute(numericIdDto: NumericIdDto) {
    const ReservaProducto = await this.getReservaProductoById(numericIdDto)
    return ReservaProducto
  }
}
