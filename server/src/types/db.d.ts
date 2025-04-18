interface PopulateConfig {
  user: {
    usuario: string
    clave: string
  }
  sucursal: {
    nombre: string
    direccion: string
    sucursalCentral: boolean
  }
  empleado: {
    nombre: string
    apellidos: string
    activo: boolean
  }
  rolesDefault: string[]
  defaultCategoria: {
    nombre: string
    descripcion?: string
  }
  defaultMarca: {
    nombre: string
    descripcion?: string
  }
  coloresDefault: Array<{
    nombre: string
    hex: string
  }>
  estadosTransferenciasInvDefault: Array<{
    nombre: string
    codigo: string
  }>
  tiposDocumentoClienteDefault: Array<{
    nombre: string
    codigoSunat: string
    codigo: string
  }>
  tiposDocumentoFacturacionDefault: Array<{
    nombre: string
    codigoSunat: string
    codigo: string
  }>
  monedasFacturacionDefault: Array<{
    nombre: string
    codigoSunat: string
  }>
  metodosPagoDefault: Array<{
    nombre: string
    codigoTipo: string
    codigoSunat: string
    activado: boolean
  }>
  tiposTaxDefault: Array<{
    nombre: string
    codigo: string
    porcentaje: number
    codigoSunat: string
  }>
  estadosDocFacturacion: Array<{
    nombre: string
    codigo: string
    codigoSunat: string
  }>
}

interface SeedConfig {
  cuentas: {
    admin: {
      usuario: string
      clave: string
    }
    vendedor: {
      usuario: string
      clave: string
    }
    computadora: {
      usuario: string
      clave: string
    }
  }
  rolesDefault: string[]
  categoriasDefault: string[]
  marcasDefault: string[]
  coloresDefault: Array<{
    nombre: string
    hex: string
  }>
  estadosTransferenciasInvDefault: Array<{
    nombre: string
    codigo: string
  }>
  tiposDocumentoClienteDefault: Array<{
    nombre: string
    codigoSunat: string
    codigo: string
  }>
  tiposDocumentoFacturacionDefault: Array<{
    nombre: string
    codigoSunat: string
    codigo: string
  }>
  monedasFacturacionDefault: Array<{
    nombre: string
    codigoSunat: string
  }>
  metodosPagoDefault: Array<{
    nombre: string
    codigoTipo: string
    codigoSunat: string
    activado: boolean
  }>
  tiposTaxDefault: Array<{
    nombre: string
    codigo: string
    porcentaje: number
    codigoSunat: string
  }>
  estadosDocFacturacion: Array<{
    nombre: string
    codigo: string
    codigoSunat: string
  }>
  sucursalesCount: number
  empleadosCount: number
  productosCount: number
  proformasVentaCount: number
  notificacionesCount: number
  clientesCount: number
  transferenciasInventariosCount: number
  ventasCount: number
}
