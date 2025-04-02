import { accessTokenCookieName, apiBaseUrl } from '@/core/consts'
import { getCookie } from '@/core/lib/cookies'
import { refreshAccessToken } from '@/core/lib/auth'
import { tryCatch, tryCatchAll } from '@/core/lib/try-catch'

export async function customFetch(url: string, options?: RequestInit) {
  const { data: res, error } = await tryCatchAll(fetch(url, options))

  if (error != null) {
    return {
      fetchError: {
        message: 'Network error'
      }
    }
  }

  return { res }
}

export async function httpRequest<T>(
  url: string,
  options?: ((accessToken: string) => RequestInit) | RequestInit
): Promise<ResultAll<T, { message: string; action?: () => void }>> {
  const optionsIsFn = typeof options === 'function'

  let requestOptions = undefined

  if (optionsIsFn) {
    let accessToken = getCookie(accessTokenCookieName)

    if (accessToken == null || accessToken.length < 1) {
      const { data, error } = await refreshAccessToken()

      if (error != null) {
        return {
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

    requestOptions = options(accessToken)
  } else {
    requestOptions = options
  }

  const { res, fetchError } = await customFetch(
    `${apiBaseUrl}${url}`,
    requestOptions
  )

  if (fetchError != null) {
    return {
      error: fetchError
    }
  }

  try {
    const textResponse = await res.text()
    const json = JSON.parse(textResponse)

    if (json.status !== 'success') {
      return { error: { message: String(json.error) } }
    }

    return { data: json.data }
  } catch {
    return {
      error: { message: 'Unexpected format response' }
    }
  }
}
