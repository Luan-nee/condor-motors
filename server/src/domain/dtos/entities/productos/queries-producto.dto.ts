import { filterTypeValues, orderValues } from '@/consts'
import { CustomError } from '@/core/errors/custom.error'
import { queriesProductoValidator } from '@/domain/validators/entities/productos/producto.validator'
import type {
  FilterTypeValuesType,
  OrderValuesType,
  QueriesDtoType
} from '@/types/zod'

export class QueriesProductoDto {
  sort_by: QueriesDtoType['sort_by']
  order: OrderValuesType
  page: QueriesDtoType['page']
  search: QueriesDtoType['search']
  page_size: QueriesDtoType['page_size']
  filter: QueriesDtoType['filter']
  filter_value?: QueriesDtoType['filter_value']
  filter_type: FilterTypeValuesType
  stockBajo?: string
  activo?: string
  stock?: {
    value: number
    filterType?: string
  }

  private constructor({
    sort_by: sortBy,
    order,
    page,
    search,
    page_size: pageSize,
    filter,
    filter_value: filterValue,
    filter_type: filterType,
    stockBajo,
    activo,
    stock
  }: QueriesProductoDto) {
    this.sort_by = sortBy
    this.order = order
    this.page = page
    this.search = search
    this.page_size = pageSize
    this.filter = filter
    this.filter_value = filterValue
    this.filter_type = filterType
    this.stockBajo = stockBajo
    this.activo = activo
    this.stock = stock
  }

  private static isValidFilterType(
    filterType: string
  ): filterType is keyof typeof filterTypeValues {
    return Object.keys(filterTypeValues).includes(filterType)
  }

  private static isValidOrder(
    order: string
  ): order is keyof typeof orderValues {
    return Object.keys(orderValues).includes(order)
  }

  static create(input: any): [string?, QueriesProductoDto?] {
    const result = queriesProductoValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    if (!this.isValidFilterType(result.data.filter_type)) {
      throw CustomError.internalServer()
    }

    if (!this.isValidOrder(result.data.order)) {
      throw CustomError.internalServer()
    }

    return [
      undefined,
      new QueriesProductoDto({
        sort_by: result.data.sort_by,
        order: result.data.order,
        page: result.data.page,
        search: result.data.search,
        page_size: result.data.page_size,
        filter: result.data.filter,
        filter_value: result.data.filter_value,
        filter_type: result.data.filter_type,
        stockBajo: result.data.stockBajo,
        activo: result.data.activo,
        stock: result.data.stock
      })
    ]
  }
}
