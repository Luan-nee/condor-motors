import type { fileTypeValues, filterTypeValues, orderValues } from '@/consts'
import type { QueriesSchema } from '@/domain/validators/query-params/query-params.validator'
import type z from 'zod'

export type OrderValuesType = keyof typeof orderValues
export type FilterTypeValuesType = keyof typeof filterTypeValues

export type QueriesDtoType = z.infer<typeof QueriesSchema>

export type FileTypeValues =
  (typeof fileTypeValues)[keyof typeof fileTypeValues]
