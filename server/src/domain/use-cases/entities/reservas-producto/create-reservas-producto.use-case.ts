import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  clientesTable,
  reservasProductosTable,
  sucursalesTable
} from '@/db/schema'
import type { CreateReservasProductoDto } from '@/domain/dtos/entities/reservas-producto/create-reservasProducto.dto'
import { eq } from 'drizzle-orm'

export class CreateReservasProducto {
  private async createReservasProducto(
    createReservasProductoDto: CreateReservasProductoDto
  ) {
    const clienteIdExist = await db
      .select()
      .from(clientesTable)
      .where(eq(clientesTable.id, createReservasProductoDto.clienteId))

    if (clienteIdExist.length <= 0) {
      throw CustomError.badRequest(
        `El ID: ${createReservasProductoDto.clienteId} no existe`
      )
    }

    const sucursalId = await db
      .select()
      .from(sucursalesTable)
      .where(eq(sucursalesTable.id, createReservasProductoDto.sucursalId))

    if (sucursalId.length <= 0) {
      throw CustomError.badRequest(
        `No existe la sucursal ${createReservasProductoDto.sucursalId}`
      )
    }

    const insertReservaProductos = await db
      .insert(reservasProductosTable)
      .values({
        descripcion: createReservasProductoDto.descripcion,
        detallesReserva: createReservasProductoDto.detallesReserva,
        montoAdelantado: createReservasProductoDto.montoAdelantado.toFixed(2),
        fechaRecojo: createReservasProductoDto.fechaRecojo,
        clienteId: createReservasProductoDto.clienteId,
        sucursalId: createReservasProductoDto.sucursalId
      })
      .returning({ id: reservasProductosTable.id })

    if (insertReservaProductos.length < 1) {
      throw CustomError.internalServer(
        'ocurrio un error al crear una reservacion'
      )
    }
    const [ReservaProducto] = insertReservaProductos

    return ReservaProducto
  }

  async execute(createReservasProductoDto: CreateReservasProductoDto) {
    const reservasProducto = await this.createReservasProducto(
      createReservasProductoDto
    )
    return reservasProducto
  }
}
