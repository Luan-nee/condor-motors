import { tiposDocClienteCodes } from '@/consts'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { clientesTable, tiposDocumentoClienteTable } from '@/db/schema'
import type { UpdateClienteDto } from '@/domain/dtos/entities/clientes/update-cliente.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { Validator } from '@/domain/validators/validator'
import { eq } from 'drizzle-orm'

export class UpdateCliente {
  private async updateCliente(
    numericIdDto: NumericIdDto,
    updateClienteDto: UpdateClienteDto
  ) {
    const clientes = await db
      .select({
        id: clientesTable.id,
        tipoDocCodigo: tiposDocumentoClienteTable.codigo
      })
      .from(clientesTable)
      .innerJoin(
        tiposDocumentoClienteTable,
        eq(clientesTable.tipoDocumentoId, tiposDocumentoClienteTable.id)
      )
      .where(eq(clientesTable.id, numericIdDto.id))

    if (clientes.length <= 0) {
      throw CustomError.badRequest(
        `No se pudo actualizar el cliente especificado (No se encontró)`
      )
    }

    const [cliente] = clientes

    this.validateDocCliente(updateClienteDto, cliente.tipoDocCodigo)

    const results = await db
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

    if (results.length <= 0) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar actualizar los datos del cliente'
      )
    }

    const [result] = results

    return result
  }

  // eslint-disable-next-line complexity
  private validateDocCliente(
    updateClienteDto: UpdateClienteDto,
    tipoDocumentoCodigo: string
  ) {
    if (
      tipoDocumentoCodigo === tiposDocClienteCodes.dni ||
      tipoDocumentoCodigo === tiposDocClienteCodes.ruc ||
      tipoDocumentoCodigo === tiposDocClienteCodes.noDomiciliadoSinRuc
    ) {
      if (updateClienteDto.numeroDocumento === undefined) {
        if (tipoDocumentoCodigo === tiposDocClienteCodes.ruc) {
          if (updateClienteDto.direccion == null) {
            throw CustomError.badRequest('La dirección es requerida')
          }
        }

        return
      }

      if (updateClienteDto.numeroDocumento === null) {
        throw CustomError.badRequest('El numero de documento es requerido')
      }

      if (!Validator.isOnlyNumbers(updateClienteDto.numeroDocumento)) {
        throw CustomError.badRequest(
          'El numero de documento solo puede contener números'
        )
      }

      if (
        tipoDocumentoCodigo === tiposDocClienteCodes.dni &&
        updateClienteDto.numeroDocumento.length !== 8
      ) {
        throw CustomError.badRequest(
          'Si el tipo de documento es dni este solo puede contener números y tener 8 caracteres de longitud'
        )
      }

      if (tipoDocumentoCodigo === tiposDocClienteCodes.ruc) {
        if (updateClienteDto.numeroDocumento.length !== 11) {
          throw CustomError.badRequest(
            'Si el tipo de documento es ruc este solo puede contener números y tener 11 caracteres de longitud'
          )
        }

        if (updateClienteDto.direccion == null) {
          throw CustomError.badRequest('La dirección es requerida')
        }
      }
    }
  }

  async execute(
    updateClienteDto: UpdateClienteDto,
    numericIdDto: NumericIdDto
  ) {
    const cliente = await this.updateCliente(numericIdDto, updateClienteDto)

    return cliente
  }
}
