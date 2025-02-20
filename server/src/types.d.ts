interface AuthPayload {
  id: number
  rolCuentaEmpleadoId: number
  empleadoId: number
}

interface UserEntity {
  id: string
  usuario: string
  fechaRegistro: string
  rolCuentaEmpleadoId: string
  empleadoId: string
}

interface UserEntityWithTokens {
  accessToken: string
  refreshToken: string
  user: UserEntity
}

type ObjectAny = Record<string, any>
