import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { clientesTable } from '@/db/schema'
import type { CreateClienteDto } from '@/domain/dtos/entities/clientes/create-cliente.dto'
import { count, eq } from 'drizzle-orm'

export class CreateCliente {
  private async createCliente(createClienteDto: CreateClienteDto) {
    const clienteDni = await db
      .select({ count: count(clientesTable.id) })
      .from(clientesTable)
      .where(
        eq(clientesTable.numeroDocumento, createClienteDto.numeroDocumento)
      )

    if (clienteDni[0].count > 0) {
      throw CustomError.badRequest(
        `El numero de documento ingresado ya esta en uso : ${createClienteDto.numeroDocumento} `
      )
    }

    const InsertValuesCliente = await db
      .insert(clientesTable)
      .values({
        tipoDocumentoId: createClienteDto.tipoDocumentoId,
        numeroDocumento: createClienteDto.numeroDocumento,
        denominacion: createClienteDto.denominacion,
        codigoPais: createClienteDto.codigoPais,
        direccion: createClienteDto.direccion,
        correo: createClienteDto.correo,
        telefono: createClienteDto.telefono
      })
      .returning()

    if (InsertValuesCliente.length <= 0) {
      throw CustomError.internalServer('Ocurrio un error al agregar al cliente')
    }
    const [cliente] = InsertValuesCliente
    return cliente
  }

  async execute(createClienteDto: CreateClienteDto) {
    const cliente = await this.createCliente(createClienteDto)
    return cliente
  }
}
