import { orderValues } from '@/consts'
import { db } from '@/db/connection'
import {
  estadosTransferenciasInventarios,
  sucursalesTable,
  transferenciasInventariosTable
} from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { and, asc, desc, eq, ilike, or } from 'drizzle-orm'

export class GetTransferenciasInventarios {
  private readonly selectFields = {
    estado: estadosTransferenciasInventarios.nombre,
    nombreSucursalOrigen: sucursalesTable.nombre,
    nombreSucursalDestino: sucursalesTable.nombre,
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

    const whereCondition =
      queriesDto.search.length > 0
        ? or(
            eq(estadosTransferenciasInventarios.id, Number(queriesDto.filter)),
            ilike(sucursalesTable.nombre, `%${queriesDto.search}%`)
          )
        : undefined

    const TransferenciasInventario = await db
      .select(this.selectFields)
      .from(transferenciasInventariosTable)
      .leftJoin(
        sucursalesTable,
        and(
          eq(
            sucursalesTable.id,
            transferenciasInventariosTable.sucursalOrigenId
          ),
          eq(
            sucursalesTable.id,
            transferenciasInventariosTable.sucursalDestinoId
          )
        )
      )
      .leftJoin(
        estadosTransferenciasInventarios,
        eq(
          estadosTransferenciasInventarios.id,
          transferenciasInventariosTable.estadoTransferenciaId
        )
      )
      .where(whereCondition)
      .groupBy(transferenciasInventariosTable.id)
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
