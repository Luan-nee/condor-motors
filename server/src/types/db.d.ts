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
    nombreRol: string
  }
}
