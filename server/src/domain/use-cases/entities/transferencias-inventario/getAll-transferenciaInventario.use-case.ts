import { orderValues } from '@/consts'
import { db } from '@/db/connection'
import {
  estadosTransferenciasInventarios,
  sucursalesTable,
  transferenciasInventariosTable
} from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { aliasedTable, asc, desc, eq } from 'drizzle-orm'

export class GetTransferenciasInventarios {
  private readonly sucursalOrigen = aliasedTable(
    sucursalesTable,
    'sucursalOrigen'
  )
  private readonly selectFields = {
    id: transferenciasInventariosTable.id,
    estado: {
      nombre: estadosTransferenciasInventarios.nombre,
      codigo: estadosTransferenciasInventarios.codigo
    },
    sucursalOrigen: {
      id: this.sucursalOrigen.id,
      nombre: this.sucursalOrigen.nombre
    },
    sucursalDestino: {
      id: sucursalesTable.id,
      nombre: sucursalesTable.nombre
    },
    modificable: transferenciasInventariosTable.modificable,
    salidaOrigen: transferenciasInventariosTable.salidaOrigen,
    llegadaDestino: transferenciasInventariosTable.llegadaDestino
  }

  private readonly validSortBy = {
    salidaOrigen: transferenciasInventariosTable.salidaOrigen,
    llegadaDestino: transferenciasInventariosTable.llegadaDestino
  } as const

  private isValidSortBy(
    sortBy: string
  ): sortBy is keyof typeof this.validSortBy {
    return Object.keys(this.validSortBy).includes(sortBy)
  }

  private getSortByColum(sortBy: string) {
    if (
      Object.keys(this.validSortBy).includes(sortBy) &&
      this.isValidSortBy(sortBy)
    ) {
      return this.validSortBy[sortBy]
    }
    return this.validSortBy.salidaOrigen
  }

  private async getRelated(queriesDto: QueriesDto) {
    const sortByColumn = this.getSortByColum(queriesDto.sort_by)
    const order =
      queriesDto.order === orderValues.asc
        ? asc(sortByColumn)
        : desc(sortByColumn)

    const transferenciasInventario = await db
      .select(this.selectFields)
      .from(transferenciasInventariosTable)
      .innerJoin(
        estadosTransferenciasInventarios,
        eq(
          estadosTransferenciasInventarios.id,
          transferenciasInventariosTable.estadoTransferenciaId
        )
      )
      .leftJoin(
        sucursalesTable,
        eq(transferenciasInventariosTable.sucursalDestinoId, sucursalesTable.id)
      )
      .leftJoin(
        this.sucursalOrigen,
        eq(
          this.sucursalOrigen.id,
          transferenciasInventariosTable.sucursalOrigenId
        )
      )
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))

    return transferenciasInventario
  }

  async execute(queriesDto: QueriesDto) {
    const transferenciaInventario = await this.getRelated(queriesDto)

    return transferenciaInventario
  }
}
