import type { QueriesDto } from '@domain/dtos/query-params/queries.dto'

export class QueriesMapper {
  static QueriesFromObject(
    queriesDto: QueriesDto,
    validSortBy: string[],
    defaultSortBy: string
  ): QueriesDto {
    const {
      sort_by: sortBy,
      order,
      page,
      search,
      page_size: pageSize
    } = queriesDto

    let mappedSortBy = sortBy

    if (!validSortBy.includes(sortBy)) {
      mappedSortBy = defaultSortBy
    }

    return {
      sort_by: mappedSortBy,
      order,
      page,
      search,
      page_size: pageSize
    }
  }
}
