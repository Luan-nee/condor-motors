import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { clientesTable } from '@/db/schema'
import type { UpdateClienteDto } from '@/domain/dtos/entities/clientes/update-cliente.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { eq } from 'drizzle-orm'

export class UpdateCliente {
  async execute(
    updateClienteDto: UpdateClienteDto,
    numericIdDto: NumericIdDto
  ) {
    const cliente = await db
      .select()
      .from(clientesTable)
      .where(eq(clientesTable.id, numericIdDto.id))

    if (cliente.length <= 0) {
      throw CustomError.badRequest(
        `No se encontro ningun cliente con el id ${numericIdDto.id}`
      )
    }

    const updateClienteResult = await db
      .update(clientesTable)
      .set({
        numeroDocumento: updateClienteDto.numeroDocumento,
        denominacion: updateClienteDto.denominacion,
        direccion: updateClienteDto.direccion,
        correo: updateClienteDto.correo,
        telefono: updateClienteDto.telefono
      })
      .where(eq(clientesTable.id, numericIdDto.id))
      .returning()

    if (updateClienteResult.length <= 0) {
      throw CustomError.internalServer(
        'ocurrio un error al intentar actualizar los datos del cliente'
      )
    }
    const [clientes] = updateClienteResult
    return clientes
  }
}
