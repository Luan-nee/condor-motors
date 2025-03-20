import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { clientesTable } from '@/db/schema'
import type { CreateClienteDto } from '@/domain/dtos/entities/clientes/create-cliente.dto'
import { count, ilike } from 'drizzle-orm'

export class CreateCliente {
  private async createCliente(createClienteDto: CreateClienteDto) {
    const whereCondition =
      createClienteDto.dni === undefined
        ? createClienteDto.ruc === undefined
          ? undefined
          : ilike(clientesTable.ruc, createClienteDto.ruc)
        : ilike(clientesTable.dni, createClienteDto.dni)

    const clienteDni = await db
      .select({ count: count(clientesTable.id) })
      .from(clientesTable)
      .where(whereCondition)

    if (Number(clienteDni[0]) <= 0) {
      throw CustomError.badRequest(
        `El dni o ruc ya estan registrados para este usuario : ${createClienteDto.ruc} - ${createClienteDto.dni}`
      )
    }
    const InsertValuesCliente = await db
      .insert(clientesTable)
      .values({
        nombresApellidos: createClienteDto.nombresApellidos,
        dni: createClienteDto.dni,
        razonSocial: createClienteDto.razonSocial,
        ruc: createClienteDto.ruc,
        telefono: createClienteDto.telefono,
        correo: createClienteDto.correo,
        tipoPersonaId: createClienteDto.tipoPersonaId
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
