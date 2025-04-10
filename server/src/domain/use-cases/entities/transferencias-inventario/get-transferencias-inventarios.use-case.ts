import { orderValues } from '@/consts'
import { db } from '@/db/connection'
import {
  estadosTransferenciasInventarios,
  sucursalesTable,
  transferenciasInventariosTable
} from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import {
  aliasedTable,
  and,
  asc,
  count,
  desc,
  eq,
  like,
  type SQL
} from 'drizzle-orm'

export class GetTransferenciasInventarios {
  private readonly sucursalOrigen = aliasedTable(
    sucursalesTable,
    'sucursalOrigen'
  )
  private readonly selectFields = {
    id: transferenciasInventariosTable.id,
    estado: {
      id: estadosTransferenciasInventarios.id,
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

  private readonly validFilter = {
    estado: estadosTransferenciasInventarios.codigo
  } as const

  private isValidSortBy(
    sortBy: string
  ): sortBy is keyof typeof this.validSortBy {
    return Object.keys(this.validSortBy).includes(sortBy)
  }

  private getSortByColum(sortBy: string) {
    if (this.isValidSortBy(sortBy)) {
      return this.validSortBy[sortBy]
    }
    return this.validSortBy.salidaOrigen
  }

  private getMetadata() {
    return {
      sortByOptions: Object.keys(this.validSortBy)
    }
  }

  private isValidFilter(
    filter: string
  ): filter is keyof typeof this.validFilter {
    return Object.keys(this.validFilter).includes(filter)
  }

  private getFilterColumn(filter: string) {
    if (this.isValidFilter(filter)) {
      return this.validFilter[filter]
    }

    return undefined
  }

  private getFilterCondition(queriesDto: QueriesDto) {
    const conditions: SQL[] = []

    const filterColumn = this.getFilterColumn(queriesDto.filter)

    if (filterColumn === undefined || queriesDto.filter_value == null) {
      return and(...conditions)
    }

    if (queriesDto.filter_type === 'eq') {
      conditions.push(like(filterColumn, queriesDto.filter_value))
    }

    return and(...conditions)
  }

  private async getTransferenciasInvs(queriesDto: QueriesDto) {
    const sortByColumn = this.getSortByColum(queriesDto.sort_by)
    const order =
      queriesDto.order === orderValues.asc
        ? asc(sortByColumn)
        : desc(sortByColumn)

    const filterCondition = this.getFilterCondition(queriesDto)

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
      .where(filterCondition)
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))

    return transferenciasInventario
  }

  private async getPagination(queriesDto: QueriesDto) {
    const filterCondition = this.getFilterCondition(queriesDto)

    const results = await db
      .select({ count: count(transferenciasInventariosTable.id) })
      .from(transferenciasInventariosTable)
      .innerJoin(
        estadosTransferenciasInventarios,
        eq(
          estadosTransferenciasInventarios.id,
          transferenciasInventariosTable.estadoTransferenciaId
        )
      )
      .where(filterCondition)

    const [totalItems] = results

    const totalPages = Math.ceil(totalItems.count / queriesDto.page_size)
    const hasNext = queriesDto.page < totalPages && queriesDto.page >= 1
    const hasPrev = queriesDto.page > 1 && queriesDto.page <= totalPages

    return {
      totalItems: totalItems.count,
      totalPages,
      currentPage: queriesDto.page,
      hasNext,
      hasPrev
    }
  }

  async execute(queriesDto: QueriesDto) {
    const metadata = this.getMetadata()
    const pagination = await this.getPagination(queriesDto)

    const isValidPage =
      (pagination.currentPage <= pagination.totalPages ||
        pagination.currentPage >= 1) &&
      pagination.totalItems > 0

    const results = isValidPage
      ? await this.getTransferenciasInvs(queriesDto)
      : []

    return {
      results,
      pagination,
      metadata
    }
  }
}
