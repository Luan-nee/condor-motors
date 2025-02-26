import { queriesValidator } from '@/domain/validators/query-params/query-params.validator'
import type { QueriesDtoType } from '@/types/zod'

export class QueriesDto {
  sort_by: QueriesDtoType['sort_by']
  order: QueriesDtoType['order']
  page: QueriesDtoType['page']
  search: QueriesDtoType['search']
  page_size: QueriesDtoType['page_size']
  filter: QueriesDtoType['filter']
  filter_value?: QueriesDtoType['filter_value']
  filter_type: QueriesDtoType['filter_type']

  private constructor({
    sort_by: sortBy,
    order,
    page,
    search,
    page_size: pageSize,
    filter,
    filter_value: filterValue,
    filter_type: filterType
  }: QueriesDto) {
    this.sort_by = sortBy
    this.order = order
    this.page = page
    this.search = search
    this.page_size = pageSize
    this.filter = filter
    this.filter_value = filterValue
    this.filter_type = filterType
  }

  static create(input: any): [string?, QueriesDto?] {
    const result = queriesValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    return [undefined, new QueriesDto(result.data)]
  }
}
