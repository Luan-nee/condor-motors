import { defaultQueries, orderValues } from '@/consts'
import z from 'zod'

// export const paramsSchema = {
//   id: z.coerce.number().positive().min(1)
// }

export const queriesBaseSchema = {
  sort_by: z.coerce.string().default(defaultQueries.sort_by),
  order: z.coerce
    .string()
    .default(defaultQueries.order)
    .transform((value) =>
      value === orderValues.desc ? orderValues.desc : orderValues.asc
    ),
  page: z.coerce
    .number()
    .default(defaultQueries.page)
    .transform((value) => (value < 1 ? 1 : value)),
  search: z.coerce.string().default(defaultQueries.search),
  page_size: z.coerce
    .number()
    .default(defaultQueries.page_size)
    .transform((value) => {
      switch (true) {
        case value < 1:
          return 1
        case value > 100:
          return 100
        default:
          return value
      }
    })
  // filter: z.coerce.string().default(defaultQueries.filter),
  // filter_value: z.coerce.string().default(defaultQueries.filter_value),
  // filter_type: z.coerce.string().default(defaultQueries.filter_type)
}
