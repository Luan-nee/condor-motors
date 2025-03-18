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
    updateAny: 'sucursales:update_any',
    // deleteAny: 'sucursales:delete_any',
    getRelated: 'sucursales:get_related'
    // updateRelated: 'sucursales:update_related'
  },
  empleados: {
    createAny: 'empleados:create_any',
    getAny: 'empleados:get_any',
    updateAny: 'empleados:update_any',
    // deleteAny: 'empleados:delete_any',
    getRelated: 'empleados:get_related'
    // updateSelf: 'empleados:update_self'
    // deleteSelf: 'empleados:delete_self',
  },
  productos: {
    createAny: 'productos:create_any',
    getAny: 'productos:get_any',
    updateAny: 'productos:update_any',
    deleteAny: 'productos:delete_any',
    createRelated: 'productos:create_related',
    getRelated: 'productos:get_related',
    updateRelated: 'productos:update_related'
  },
  inventarios: {
    addAny: 'inventarios:add_any',
    addRelated: 'inventarios:add_related'
  },
  ventas: {
    createAny: 'ventas:create_any',
    getAny: 'ventas:get_any',
    updateAny: 'ventas:update_any',
    deleteAny: 'ventas:delete_any',
    createRelated: 'ventas:create_related',
    getRelated: 'ventas:get_related',
    updateRelated: 'ventas:update_related',
    deleteRelated: 'ventas:delete_related'
  },
  categorias: {
    createAny: 'categorias:create_any'
  },
  cuentasEmpleados: {
    createAny: 'cuentas_empleados:create_any',
    getAny: 'cuentas_empleados:get_any',
    updateAny: 'cuentas_empleados:update_any',
    deleteAny: 'cuentas_empleados:delete_any',
    getRelated: 'cuentas_empleados:get_related',
    updateSelf: 'cuentas_empleados:update_self'
  },
  rolesCuentasEmpleados: {
    getAny: 'roles_cuentas_empleados:get_any'
  },
  proformasVenta: {
    createAny: 'proformas_venta:create_any',
    getAny: 'proformas_venta:get_any',
    updateAny: 'proformas_venta:update_any',
    deleteAny: 'proformas_venta:delete_any',
    createRelated: 'proformas_venta:create_related',
    getRelated: 'proformas_venta:get_related',
    updateRelated: 'proformas_venta:update_related',
    deleteRelated: 'proformas_venta:delete_related'
  }
} as const
