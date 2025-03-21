import { orderValues } from '@/consts'
import { db } from '@/db/connection'
import { clientesTable, tiposDocumentoClienteTable } from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { asc, desc, eq, ilike, or, type SQL } from 'drizzle-orm'

export class GetClientes {
  private readonly selectFields = {
    id: clientesTable.id,
    tipoDocumentoId: clientesTable.tipoDocumentoId,
    nombre: tiposDocumentoClienteTable.nombre,
    numeroDocumento: clientesTable.numeroDocumento,
    denominacion: clientesTable.denominacion,
    codigoPais: clientesTable.codigoPais,
    direccion: clientesTable.direccion,
    correo: clientesTable.correo,
    telefono: clientesTable.telefono,
    fechaCreacion: clientesTable.fechaCreacion,
    fechaActualizacion: clientesTable.fechaActualizacion
  }

  private readonly validSortBy = {
    fechaCreacion: clientesTable.fechaCreacion,
    fechaActualizacion: clientesTable.fechaActualizacion,
    codigoPais: clientesTable.codigoPais
  } as const

  private isValidarSortBy(
    sortBy: string
  ): sortBy is keyof typeof this.validSortBy {
    return Object.keys(this.validSortBy).includes(sortBy)
  }

  private GetSortByColumn(sortBY: string) {
    if (
      Object.keys(this.validSortBy).includes(sortBY) &&
      this.isValidarSortBy(sortBY)
    ) {
      return this.validSortBy[sortBY]
    }
    return this.validSortBy.fechaCreacion
  }

  private async getRelatedClientes(
    queriesDto: QueriesDto,
    order: SQL,
    condition: SQL | undefined
  ) {
    return await db
      .select(this.selectFields)
      .from(clientesTable)
      .innerJoin(
        tiposDocumentoClienteTable,
        eq(clientesTable.tipoDocumentoId, tiposDocumentoClienteTable.id)
      )
      .where(condition)
      .orderBy(order)
      .limit(queriesDto.page_size)
  }

  private async getClientes(queriesDto: QueriesDto) {
    const sortByColumn = this.GetSortByColumn(queriesDto.sort_by)

    const order =
      queriesDto.order === orderValues.asc
        ? asc(sortByColumn)
        : desc(sortByColumn)

    const condition =
      queriesDto.search.length > 0
        ? or(
            ilike(clientesTable.numeroDocumento, `%${queriesDto.search}%`),
            ilike(clientesTable.codigoPais, `%${queriesDto.search}%`),
            ilike(clientesTable.denominacion, `%${queriesDto.search}%`),
            ilike(clientesTable.direccion, `%${queriesDto.search}%`),
            ilike(clientesTable.correo, `%${queriesDto.search}%`),
            ilike(clientesTable.telefono, `%${queriesDto.search}%`)
          )
        : undefined

    const clientes = await this.getRelatedClientes(queriesDto, order, condition)

    if (clientes.length <= 0) {
      return []
    }
    return clientes
  }

  async execute(queriesDto: QueriesDto) {
    const clientes = await this.getClientes(queriesDto)
    return clientes
  }
}
