interface PopulateConfig {
  user: {
    usuario: string
    clave: string
  }
  sucursal: {
    nombre: string
    sucursalCentral: boolean
    direccion: string
  }
  empleado: {
    nombre: string
    apellidos: string
    activo: boolean
    dni: string
  }
  rolEmpleado: {
    codigo: string
    nombreRol: string
  }
  defaultCategoria: {
    nombre: string
    descripcion?: string
  }
  defaultMarca: {
    nombre: string
    descripcion?: string
  }
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
  estadosTransferenciasInventariosDefault: string[]
  tiposPersonasDefault: string[]
  sucursalesCount: number
  empleadosCount: number
  productosCount: number
  proformasVentaCount: number
  notificacionesCount: number
}
