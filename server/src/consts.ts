import { envs } from '@/config/envs'

export const refreshTokenCookieName = 'refresh_token'
export const isProduction = envs.NODE_ENV === 'production'
export const databaseEnableSSL = envs.DATABASE_ENABLE_SSL === true

export const orderValues = {
  asc: 'asc',
  desc: 'desc'
} as const

export const filterTypeValues = {
  eq: 'eq',
  gt: 'gt',
  lt: 'lt',
  after: 'after',
  before: 'before'
} as const

export const defaultQueries = {
  search: '',
  sort_by: '',
  order: orderValues.desc,
  page: 1,
  page_size: 10,
  filter: '',
  filter_value: undefined,
  filter_type: filterTypeValues.eq
}

export const responseStatus = {
  success: 'success',
  fail: 'fail',
  error: 'error'
} as const

export const permissionCodes = {
  sucursales: {
    createAny: 'sucursales:create_any',
    getAny: 'sucursales:get_any',
    upateAny: 'sucursales:update_any',
    deleteAny: 'sucursales:delete_any',
    getRelated: 'sucursales:get_related',
    updateRelated: 'sucursales:update_related'
  },
  empleados: {
    createAny: 'empleados:create',
    getAny: 'empleados:get_any'
  }
} as const
