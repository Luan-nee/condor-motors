import { accessTokenCookieName, apiBaseUrl } from '@/core/consts'
import { getCookie } from '@/core/lib/cookies'
import { refreshAccessToken } from '@/core/lib/auth'
import { tryCatch } from '@/core/lib/try-catch'
import type { T } from 'node_modules/tailwindcss/dist/types-B254mqw1.d.mts'

interface Success<T> {
  data: T
  error: null
}

interface Failure<E> {
  data: null
  error: E
}

type Result<T, E> = Success<T> | Failure<E>

type HttpRequest = (
  url: string,
  options: (accessToken: string) => any
) => Promise<Result<T, { message: string; action?: () => void }>>

export const httpRequest: HttpRequest = async (url, options) => {
  let accessToken = getCookie(accessTokenCookieName)

  if (accessToken == null || accessToken.length < 1) {
    const { data, error } = await refreshAccessToken()

    if (error !== null) {
      return {
        data: null,
        error: {
          message: error.message,
          action: () => {
            window.location.replace('/login')
          }
        }
      }
    }

    accessToken = data.accessToken
  }

  const { data: res, error } = await tryCatch(
    fetch(`${apiBaseUrl}${url}`, options(accessToken))
  )

  if (error != null) {
    return {
      error: { message: 'Network error' },
      data: null
    }
  }

  try {
    const textResponse = await res.text()
    const json = JSON.parse(textResponse)

    if (json.status !== 'success') {
      return { data: null, error: { message: String(json.error) } }
    }

    return { data: json.data as T, error: null } as Success<T>
  } catch {
    return {
      data: null,
      error: { message: 'Unexpected format response' }
    } as Failure<{ message: string }>
  }
}
