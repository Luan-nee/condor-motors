interface Success<T> {
  data: T;
  error: null;
}

interface Failure<E> {
  data: null;
  error: E;
}

type Result<T, E> = Success<T> | Failure<E>;
type Method<A, T, E> = (args: A) => Promise<Result<T, E>>;

interface LoginSuccess {
  message: string;
  action: () => void;
}

interface SimplifiedError {
  message: string;
}

type AuthLogin = Method<
  {
    username: string;
    password: string;
  },
  LoginSuccess,
  SimplifiedError
>;

interface TestUserSuccess {
  user: {
    id: number;
    usuario: string;
    rol: {
      codigo: string;
      nombre: string;
    };
  };
}

type TestSession = Method<
  void,
  TestUserSuccess,
  SimplifiedError & { action: () => void }
>;
