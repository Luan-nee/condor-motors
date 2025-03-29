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
  private readonly sucursalDestino = aliasedTable(
    sucursalesTable,
    'sucursalDestino'
  )
  private readonly selectFields = {
    id: transferenciasInventariosTable.id,
    estado: estadosTransferenciasInventarios.nombre,
    nombreSucursalOrigen: this.sucursalOrigen.nombre,
    nombreSucursalDestino: this.sucursalDestino.nombre,
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

    const TransferenciasInventario = await db
      .select(this.selectFields)
      .from(transferenciasInventariosTable)
      .leftJoin(
        this.sucursalOrigen,
        eq(
          this.sucursalOrigen.id,
          transferenciasInventariosTable.sucursalOrigenId
        )
      )
      .leftJoin(
        this.sucursalDestino,
        eq(
          this.sucursalDestino.id,
          transferenciasInventariosTable.sucursalDestinoId
        )
      )
      .leftJoin(
        estadosTransferenciasInventarios,
        eq(
          estadosTransferenciasInventarios.id,
          transferenciasInventariosTable.estadoTransferenciaId
        )
      )
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))

    return TransferenciasInventario
  }

  async execute(queriesDto: QueriesDto) {
    const transferenciaInventario = await this.getRelated(queriesDto)

    return transferenciaInventario
  }
}
