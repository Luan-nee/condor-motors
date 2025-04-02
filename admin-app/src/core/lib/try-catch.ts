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
