import { tiposDocClienteCodes } from '@/consts'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { clientesTable, tiposDocumentoClienteTable } from '@/db/schema'
import type { NumericDocDto } from '@/domain/dtos/query-params/numeric-doc.dto'
import type { ConsultService } from '@/types/interfaces'
import { eq, inArray } from 'drizzle-orm'

export class GetClienteByDoc {
  constructor(private readonly consultService: ConsultService) {}

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

  private async getClienteByDoc(numericDocDto: NumericDocDto) {
    const clientes = await db
      .select(this.selectFields)
      .from(clientesTable)
      .innerJoin(
        tiposDocumentoClienteTable,
        eq(tiposDocumentoClienteTable.id, clientesTable.tipoDocumentoId)
      )
      .where(eq(clientesTable.numeroDocumento, numericDocDto.doc))

    if (clientes.length > 0) {
      const [cliente] = clientes

      return cliente
    }

    const { data, error } = await this.consultService.searchClient({
      numeroDocumento: numericDocDto.doc
    })

    if (error != null) {
      throw CustomError.badRequest(
        `No se encontró ninguna persona con ese número de documento: ${numericDocDto.doc}`
      )
    }

    const tiposDocumentos = await db
      .select({
        id: tiposDocumentoClienteTable.id,
        codigo: tiposDocumentoClienteTable.codigo
      })
      .from(tiposDocumentoClienteTable)
      .where(
        inArray(tiposDocumentoClienteTable.codigo, [
          tiposDocClienteCodes.dni,
          tiposDocClienteCodes.ruc
        ])
      )

    const responseWithoutDocumentType = {
      id: null,
      tipoDocumentoId: null,
      numeroDocumento: data.numeroDocumento,
      denominacion: data.denominacion,
      direccion: data.direccion
    }

    if (tiposDocumentos.length < 2) {
      return responseWithoutDocumentType
    }

    const dniTipoDocumento = tiposDocumentos.find(
      (td) => td.codigo === tiposDocClienteCodes.dni
    )
    const rucTipoDocumento = tiposDocumentos.find(
      (td) => td.codigo === tiposDocClienteCodes.ruc
    )

    const isDni = numericDocDto.doc.length === 8
    const tipoDocumentoId = isDni ? dniTipoDocumento?.id : rucTipoDocumento?.id

    if (tipoDocumentoId == null) {
      return responseWithoutDocumentType
    }

    return {
      id: null,
      tipoDocumentoId,
      numeroDocumento: data.numeroDocumento,
      denominacion: data.denominacion,
      direccion: data.direccion
    }
  }

  async execute(numericDocDto: NumericDocDto) {
    const cliente = await this.getClienteByDoc(numericDocDto)

    return cliente
  }
}
