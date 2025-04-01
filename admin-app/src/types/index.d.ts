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

type AuthLogin = Method<
  {
    username: string
    password: string
  },
  LoginSuccess,
  ApiError
>

interface TestUserSuccess {
  user: {
    id: number
    usuario: string
    rol: {
      codigo: string
      nombre: string
    }
  }
}

type TestSession = Method<void, TestUserSuccess, ApiErrorWithAction>

type RefreshAccessToken = Method<void, TestUserSuccess, ApiError>

type AuthLogout = Method<void, ApiSuccessWithAction, ApiErrorWithAction>
