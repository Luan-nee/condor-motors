import { tiposDocClienteCodes } from '@/consts'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { clientesTable, tiposDocumentoClienteTable } from '@/db/schema'
import type { CreateClienteDto } from '@/domain/dtos/entities/clientes/create-cliente.dto'
import { Validator } from '@/domain/validators/validator'
import { eq } from 'drizzle-orm'

export class CreateCliente {
  private async createCliente(createClienteDto: CreateClienteDto) {
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

    if (clientes.length < 1) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar crear el cliente'
      )
    }

    const [cliente] = clientes

    return cliente
  }

  // eslint-disable-next-line complexity
  private async validateDocCliente(createClienteDto: CreateClienteDto) {
    const tiposDocumento = await db
      .select({
        id: tiposDocumentoClienteTable.id,
        codigo: tiposDocumentoClienteTable.codigo
      })
      .from(tiposDocumentoClienteTable)
      .where(
        eq(tiposDocumentoClienteTable.id, createClienteDto.tipoDocumentoId)
      )

    if (tiposDocumento.length < 1) {
      throw CustomError.badRequest(
        'El tipo de documento de cliente especificado no existe'
      )
    }

    const [tipoDocumento] = tiposDocumento

    if (
      tipoDocumento.codigo === tiposDocClienteCodes.dni ||
      tipoDocumento.codigo === tiposDocClienteCodes.ruc ||
      tipoDocumento.codigo === tiposDocClienteCodes.noDomiciliadoSinRuc
    ) {
      if (createClienteDto.numeroDocumento == null) {
        throw CustomError.badRequest('El numero de documento es requerido')
      }

      if (!Validator.isOnlyNumbers(createClienteDto.numeroDocumento)) {
        throw CustomError.badRequest(
          'El numero de documento solo puede contener números'
        )
      }

      if (
        tipoDocumento.codigo === tiposDocClienteCodes.dni &&
        createClienteDto.numeroDocumento.length !== 8
      ) {
        throw CustomError.badRequest(
          'Si el tipo de documento es dni este solo puede contener números y tener 8 caracteres de longitud'
        )
      }

      if (tipoDocumento.codigo === tiposDocClienteCodes.ruc) {
        if (createClienteDto.numeroDocumento.length !== 11) {
          throw CustomError.badRequest(
            'Si el tipo de documento es ruc este solo puede contener números y tener 11 caracteres de longitud'
          )
        }

        if (createClienteDto.direccion == null) {
          throw CustomError.badRequest('La dirección es requerida')
        }
      }
    }
  }

  async execute(createClienteDto: CreateClienteDto) {
    await this.validateDocCliente(createClienteDto)

    const cliente = await this.createCliente(createClienteDto)

    return cliente
  }
}
