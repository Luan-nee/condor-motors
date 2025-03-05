interface ConfigPopulateDb {
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
  }
  rolEmpleado: {
    codigo: string
    nombreRol: string
  }
  defaultUnidad: {
    nombre: string
    descripcion?: string
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
