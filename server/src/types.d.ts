interface AuthPayload {
  id: number
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
  data: UserEntity
}

type ObjectAny = Record<string, any>
