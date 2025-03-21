import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { clientesTable, tiposDocumentoClienteTable } from '@/db/schema'
import type { NumericDocDto } from '@/domain/dtos/query-params/numeric-doc.dto'
import { eq } from 'drizzle-orm'

export class GetClienteByDoc {
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

  private async getRelatedCliente(numericDocDto: NumericDocDto) {
    return await db
      .select(this.selectFields)
      .from(clientesTable)
      .innerJoin(
        tiposDocumentoClienteTable,
        eq(tiposDocumentoClienteTable.id, clientesTable.tipoDocumentoId)
      )
      .where(eq(clientesTable.numeroDocumento, numericDocDto.doc))
  }
  private async getClienteByDoc(numericDocDto: NumericDocDto) {
    const cliente = await this.getRelatedCliente(numericDocDto)
    if (cliente.length <= 0) {
      throw CustomError.badRequest(
        `No existe ningun cliente con el documento : ${numericDocDto.doc}`
      )
    }
    const [clientes] = cliente
    return clientes
  }

  async execute(numericDocDto: NumericDocDto) {
    const cliente = await this.getClienteByDoc(numericDocDto)
    return cliente
  }
}
