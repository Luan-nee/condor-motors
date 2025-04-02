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

type AuthLogout = Method<void, ApiSuccessWithAction, ApiErrorWithAction>

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
  TestUserSuccess & { accessToken: string },
  ApiError
>
