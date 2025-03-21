import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { clientesTable, tiposDocumentoClienteTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { eq } from 'drizzle-orm'

export class GetClienteById {
  private readonly selectFields = {
    id: clientesTable.id,
    tipoDocumentoId: clientesTable.tipoDocumentoId,
    nombre: tiposDocumentoClienteTable.nombre,
    numeroDocumento: clientesTable.numeroDocumento,
    denominacion: clientesTable.denominacion,
    codigoPais: clientesTable.codigoPais,
    direccion: clientesTable.direccion,
    correo: clientesTable.correo,
    telefono: clientesTable.telefono
  }
  private async getRelatedCliente(numericIdDto: NumericIdDto) {
    const dato = String(numericIdDto.id)
    return await db
      .select(this.selectFields)
      .from(clientesTable)
      .innerJoin(
        tiposDocumentoClienteTable,
        eq(tiposDocumentoClienteTable.id, clientesTable.tipoDocumentoId)
      )
      .where(eq(clientesTable.numeroDocumento, dato))
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
