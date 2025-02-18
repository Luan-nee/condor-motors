interface ConfigPopulateDb {
  user: {
    usuario: string
    clave: string
  }
  sucursal: {
    nombre: string
    sucursalCentral: boolean
    fechaRegistro: Date
    ubicacion: string
  }
  empleado: {
    nombre: string
    apellidos: string
  }
  rolEmpleado: {
    nombreRol: string
  }
}
