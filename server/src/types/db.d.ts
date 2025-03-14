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
  rolesDefault: string[]
  categoriasDefault: string[]
  marcasDefault: string[]
  coloresDefault: string[]
  estadosTransferenciasInventariosDefault: string[]
  tiposPersonasDefault: string[]
  sucursalesCount: number
  empleadosCount: number
  productosCount: number
}
