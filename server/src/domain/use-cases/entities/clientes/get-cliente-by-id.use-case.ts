import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { clientesTable, tiposPersonasTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { eq } from 'drizzle-orm'

export class GetClienteById {
  private readonly selectFields = {
    id: clientesTable.id,
    nombreApellidos: clientesTable.nombresApellidos,
    dni: clientesTable.dni,
    razonSocial: clientesTable.razonSocial,
    ruc: clientesTable.ruc,
    telefono: clientesTable.telefono,
    correo: clientesTable.correo,
    tipoPersonaId: clientesTable.tipoPersonaId,
    nombre: tiposPersonasTable.nombre
  }
  private async getRelatedCliente(numericIdDto: NumericIdDto) {
    return await db
      .select(this.selectFields)
      .from(clientesTable)
      .innerJoin(
        tiposPersonasTable,
        eq(tiposPersonasTable.id, clientesTable.tipoPersonaId)
      )
      .where(eq(clientesTable.id, numericIdDto.id))
  }

  private async getClienteById(numericIdDto: NumericIdDto) {
    const cliente = await this.getRelatedCliente(numericIdDto)
    if (cliente.length <= 0) {
      throw CustomError.badRequest(
        `No existe ningun cliente con el id ${numericIdDto.id}`
      )
    }

    const [clientes] = cliente
    return clientes
  }

  async execute(numericIdDto: NumericIdDto) {
    const cliente = await this.getClienteById(numericIdDto)
    return cliente
  }
}
