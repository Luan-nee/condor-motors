import { apiBaseUrl } from '@/core/consts'
import { getAccessToken, refreshAccessToken } from '@/core/controllers/auth'
import { tryCatchAll } from '@/core/lib/try-catch'

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

export async function resToData<T = any>(res: Response) {
  const { data: json, error: jsonError } = await tryCatchAll(async () => {
    const textResponse = await res.text()
    return JSON.parse(textResponse)
  })

  if (jsonError != null) {
    return {
      error: {
        message: 'Unexpected format response'
      }
    }
  }

  if (json.status !== 'success') {
    return {
      error: {
        message: String(json.error)
      }
    }
  }

  return {
    data: json.data as T
  }
}

export async function resToBlob(res: Response) {
  const { data: blob, error: blobError } = await tryCatchAll(async () => {
    return await res.blob()
  })

  if (blobError != null) {
    return {
      error: {
        message: 'Unexpected format response'
      }
    }
  }

  return {
    data: blob
  }
}

async function transformRes<T = any>(res: Response, resType?: 'json' | 'blob') {
  if (resType === 'blob') {
    return await resToBlob(res)
  }

  return await resToData<T>(res)
}

export async function httpRequest<T = any>(
  url: string,
  options: HttpRequestOptions,
  resType?: 'json' | 'blob'
): HttpRequestResult<T> {
  let attempt = 0
  const maxAttempts = 2

  while (attempt < maxAttempts) {
    const { data: accessToken, error: accessTokenError } =
      await getAccessToken()

    if (accessTokenError != null) {
      return { error: accessTokenError }
    }

    const isOptionsFunction = typeof options === 'function'
    const requestOptions = isOptionsFunction ? options(accessToken) : options

    const newUrl = url.startsWith('/') ? `${apiBaseUrl}${url}` : url

    const { res, fetchError } = await customFetch(newUrl, requestOptions)

    if (fetchError) {
      return { error: fetchError }
    }

    if (res.status === 401) {
      const { error } = await refreshAccessToken()

      if (error != null) {
        return { error }
      }

      attempt++
      continue
    }

    if (res.status >= 400) {
      const { error } = await transformRes(res, 'json')

      if (error != null) {
        return { error }
      }
    }

    const { data, error } = await transformRes(res, resType)

    if (error != null) {
      return { error }
    }

    return { data }
  }

  return {
    error: {
      message: 'Max retry attempts reached. Failed to authenticate'
    }
  }
}
