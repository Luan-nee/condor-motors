export async function tryCatch<T, E = Error>(
  promise: Promise<T>
): Promise<Result<T, E>> {
  try {
    const data = await promise
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as E }
  }
}

export function tryCatchSync<T, E = Error>(fn: T): Result<T, E> {
  try {
    const data = fn
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as E }
  }
}

export function tryCatchAll<T, E = Error>(
  arg: Promise<T> | (() => MaybePromise<T>)
): ResultAll<T, E> | Promise<ResultAll<T, E>> {
  if (typeof arg === 'function') {
    try {
      const result = arg()

      return result instanceof Promise ? tryCatchAll(result) : { data: result }
    } catch (error) {
      return { error: error as E }
    }
  }

  return arg
    .then((data) => ({ data }))
    .catch((error) => ({ error: error as E }))
}
