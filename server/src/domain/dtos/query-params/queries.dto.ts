import { queriesValidator } from '@/domain/validators/query-params/query-params.validator'
import type { QueriesDtoType } from '@/types/zod'

export class QueriesDto {
  sort_by: QueriesDtoType['sort_by']
  order: QueriesDtoType['order']
  page: QueriesDtoType['page']
  search: QueriesDtoType['search']
  page_size: QueriesDtoType['page_size']

  private constructor({
    sort_by: sortBy,
    order,
    page,
    search,
    page_size: pageSize
  }: QueriesDto) {
    this.sort_by = sortBy
    this.order = order
    this.page = page
    this.search = search
    this.page_size = pageSize
  }

  static create(input: any): [string?, QueriesDto?] {
    const result = queriesValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    return [undefined, new QueriesDto(result.data)]
  }
}
