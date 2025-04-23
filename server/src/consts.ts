import { envs } from '@/config/envs'

export const refreshTokenCookieName = 'refresh_token'
export const isProduction = envs.NODE_ENV === 'production'
export const { DATABASE_ENABLE_SSL: databaseEnableSSL } = envs

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

export const maxPageSize = 100

export const defaultQueries = {
  search: '',
  sort_by: '',
  order: orderValues.desc,
  page: 1,
  page_size: 30,
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
    deleteAny: 'sucursales:delete_any',
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
    cancelAny: 'ventas:cancel_any',
    createRelated: 'ventas:create_related',
    getRelated: 'ventas:get_related',
    updateRelated: 'ventas:update_related',
    cancelRelated: 'ventas:cancel_related'
  },
  facturacion: {
    declareAny: 'facturacion:declare_any',
    declareRelated: 'facturacion:declare_related',
    syncAny: 'facturacion:sync_any',
    syncRelated: 'facturacion:sync_related',
    cancelAny: 'facturacion:cancel_any',
    cancelRelated: 'facturacion:cancel_related'
  },
  categorias: {
    createAny: 'categorias:create_any',
    updateAny: 'categorias:update_any',
    deleteAny: 'categorias:delete_any'
  },
  marcas: {
    createAny: 'marcas:create_any',
    updateAny: 'marcas:update_any',
    deleteAny: 'marcas:delete_any'
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
  },
  reservasProductos: {
    createAny: 'reservas_productos:create_any',
    deleteAny: 'reservas_productos:delete_any',
    updateAny: 'reservas_productos:update_any'
  },
  transferenciasInvs: {
    createAny: 'transferencias_inventarios:create_any',
    sendAny: 'transferencias_inventarios:send_any',
    receiveAny: 'transferencias_inventarios:receive_any',
    cancelAny: 'transferencias_inventarios:cancel_any',
    getAny: 'transferencias_inventarios:get_any',
    updateAny: 'transferencias_inventarios:update_any',
    deleteAny: 'transferencias_inventarios:delete_any',
    createRelated: 'transferencias_inventarios:create_related',
    sendRelated: 'transferencias_inventarios:send_related',
    cancelRelated: 'transferencias_inventarios:cancel_related',
    receiveRelated: 'transferencias_inventarios:receive_related',
    getRelated: 'transferencias_inventarios:get_related',
    updateRelated: 'transferencias_inventarios:update_related',
    deleteRelated: 'transferencias_inventarios:delete_related'
  },
  archivos: {
    createAny: 'archivos:create_any',
    deleteAny: 'archivos:delete_any',
    getAny: 'archivos:get_any',
    getVisible: 'archivos:get_visible'
  }
} as const

export const tiposDocFacturacionCodes = {
  factura: 'factura',
  boleta: 'boleta'
}

export const tiposTaxCodes = {
  gravado: 'gravado',
  exonerado: 'exonerado',
  gratuito: 'gratuito'
}

export const estadosTransferenciasInvCodes = {
  pedido: 'pedido',
  enviado: 'enviado',
  recibido: 'recibido'
}

export const tiposDocClienteCodes = {
  ruc: 'ruc',
  dni: 'dni',
  carnetExtranjeria: 'carnet_extranjeria',
  pasaporte: 'pasaporte',
  cedulaDiplomáticaIdentidad: 'cedula_diplomática_identidad',
  noDomiciliadoSinRuc: 'no_domiciliado_sin_ruc'
}

export const estadosDocFacturacion = {
  registrado: 'registrado-servicio-facturacion',
  enviadoSinRespuesta: 'enviado-sin-respuesta-sunat',
  aceptadoSunat: 'aceptado-sunat',
  rechazadoSunat: 'rechazado-sunat',
  anuladoSunat: 'anulado-sunat',
  porAnular: 'por-anular',
  sinRespuestaSunat: 'sin-respuesta-sunat'
}

export const logsDestination = {
  filesystem: 'filesystem',
  console: 'console',
  none: 'none'
}

export const fileTypeValues = {
  apk: 'apk',
  desktopApp: 'desktop-app',
  certificate: 'certificate'
} as const
