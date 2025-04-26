interface Success<T> {
  data: T
  error: null
}

interface Failure<E> {
  data: null
  error: E
}

type Result<T, E> = Success<T> | Failure<E>
type Method<A, T, E> = (args: A) => Promise<Result<T, E>>

interface LoginSuccess {
  message: string
  action: () => void
}

interface ApiSuccessWithAction {
  message: string
  action: () => void
}

interface ApiError {
  message: string
}

interface ApiErrorWithAction {
  message: string
  action: () => void
}

type AuthLogin = MethodAll<
  {
    username: string
    password: string
  },
  LoginSuccess,
  ApiError
>

interface TestUserSuccess {
  id: number
  usuario: string
  rolCuentaEmpleadoId: number
  rolCuentaEmpleadoCodigo: string
  empleadoId: number
  empleado: {
    activo: boolean
    nombres: string
    apellidos: string
    pathFoto: string | null
  }
  fechaCreacion: string
  fechaActualizacion: string
  sucursal: string
  sucursalId: number
}

type TestSession = MethodAll<void, TestUserSuccess, ApiErrorWithAction>

type AuthLogout = MethodAll<void, ApiSuccessWithAction, ApiErrorWithAction>

type SuccessAll<T> = {
  data: T
  error?: never
}

type FailureAll<E> = {
  data?: never
  error: E
}

type ResultAll<T, E = Error> = SuccessAll<T> | FailureAll<E>

type MaybePromise<T> = T | Promise<T>

type MethodAll<A, T, E> = (args: A) => Promise<ResultAll<T, E>>

type RefreshAccessToken = MethodAll<
  void,
  { user: TestUserSuccess; accessToken: string },
  ApiError
>

type HttpRequestOptions = ((accessToken: string) => RequestInit) | RequestInit

type HttpRequestResult<T> = Promise<
  ResultAll<T, { message: string; action?: () => void }>
>
