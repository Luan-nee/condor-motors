interface AuthPayload {
  id: number
}

interface UserEntity {
  id: number
  usuario: string
  fechaRegistro: Date
  rolCuentaEmpleadoId: string
  empleadoId: string
}

interface UserEntityWithTokens {
  accessToken: string
  refreshToken: string
  data: UserEntity
}

type ObjectAny = Record<string, any>

interface SucursalEntity {
  id: number
  nombre: string
  ubicacion?: string
  sucursalCentral: boolean
  fechaRegistro: Date
}
