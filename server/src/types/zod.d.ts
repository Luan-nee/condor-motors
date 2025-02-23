import type { QueriesSchema } from '@/domain/validators/query-params/query-params.validator'
import type z from 'zod'

export type QueriesDtoType = z.infer<typeof QueriesSchema>
