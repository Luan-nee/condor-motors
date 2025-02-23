import { envs } from '@/config/envs'

export const refreshTokenCookieName = 'refresh_token'
export const isProduction = envs.NODE_ENV === 'production'

export const orderValues = {
  asc: 'asc',
  desc: 'desc'
} as const

export const defaultQueries = {
  sort_by: '',
  order: orderValues.desc,
  page: 1,
  search: '',
  page_size: 10
  // filter: '',
  // filter_value: '',
  // filter_type: ''
}
