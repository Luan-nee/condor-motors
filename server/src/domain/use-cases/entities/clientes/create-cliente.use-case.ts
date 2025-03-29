import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { clientesTable, tiposDocumentoClienteTable } from '@/db/schema'
import type { CreateClienteDto } from '@/domain/dtos/entities/clientes/create-cliente.dto'
import { eq } from 'drizzle-orm'

export class CreateCliente {
  private async createCliente(createClienteDto: CreateClienteDto) {
    const tiposDocumentos = await db
      .select({
        id: tiposDocumentoClienteTable.id
      })
      .from(tiposDocumentoClienteTable)
      .where(
        eq(tiposDocumentoClienteTable.id, createClienteDto.tipoDocumentoId)
      )

    if (tiposDocumentos.length < 1) {
      throw CustomError.badRequest(
        'El tipo de documento de cliente enviado no existe'
      )
    }

    const clientes = await db
      .insert(clientesTable)
      .values({
        tipoDocumentoId: createClienteDto.tipoDocumentoId,
        numeroDocumento: createClienteDto.numeroDocumento,
        denominacion: createClienteDto.denominacion,
        direccion: createClienteDto.direccion,
        correo: createClienteDto.correo,
        telefono: createClienteDto.telefono
      })
      .returning()

    if (clientes.length <= 0) {
      throw CustomError.internalServer('Ocurrio un error al agregar al cliente')
    }
    const [cliente] = clientes
    return cliente
  }

  async execute(createClienteDto: CreateClienteDto) {
    const cliente = await this.createCliente(createClienteDto)
    return cliente
  }
}
