/* eslint-disable @typescript-eslint/no-unsafe-type-assertion */
import { defaultQueries, filterTypeValues, orderValues } from '@/consts'
import z from 'zod'
import { idTypeBaseSchema } from '@/domain/validators/id-type.schema'

export const paramsBaseSchema = {
  numericId: idTypeBaseSchema.numericId,
  uuid: idTypeBaseSchema.uuid
}

export const queriesBaseSchema = {
  search: z.coerce.string().trim().default(defaultQueries.search),
  sort_by: z.coerce.string().trim().default(defaultQueries.sort_by),
  order: z.coerce
    .string()
    .trim()
    .default(defaultQueries.order)
    .transform((value) => {
      if (
        Object.values(orderValues).includes(value as keyof typeof orderValues)
      ) {
        return value
      }

      return defaultQueries.order
    }),
  page: z.coerce
    .number()
    .default(defaultQueries.page)
    .transform((value) => (value < 1 ? 1 : value)),
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
    }),
  filter: z.coerce.string().trim().default(defaultQueries.filter),
  filter_value: z.any().default(defaultQueries.filter_value),
  filter_type: z.coerce
    .string()
    .trim()
    .default(defaultQueries.filter_type)
    .transform((value) => {
      if (
        Object.values(filterTypeValues).includes(
          value as keyof typeof filterTypeValues
        )
      ) {
        return value
      }

      return defaultQueries.filter_type
    })
}
