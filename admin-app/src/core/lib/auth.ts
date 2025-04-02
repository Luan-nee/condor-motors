import { deleteCookie, getCookie, setCookie } from '@/core/lib/cookies'
import { accessTokenCookieName, apiBaseUrl } from '@/core/consts'
import { customFetch, resToData } from '@/core/lib/network'
import { routes } from '@/core/routes'

export const refreshAccessToken: RefreshAccessToken = async () => {
  const { res, fetchError } = await customFetch(
    `${apiBaseUrl}/api/auth/refresh`,
    {
      method: 'POST',
      headers: {
        'Content-type': 'application/json'
      },
      credentials: 'include'
    }
  )

  if (fetchError != null) {
    return {
      error: fetchError
    }
  }

  const accessToken = res.headers.get('Authorization')

  if (accessToken == null) {
    return {
      error: { message: 'Ocurrió un error al intentar refrescar la sesión' }
    }
  }

  setCookie(accessTokenCookieName, accessToken, 15)

  const { data, error } = await resToData(res)

  if (error != null) {
    return { error }
  }

  return {
    data: {
      accessToken: accessToken,
      user: data
    }
  }
}

export async function getAccessToken() {
  const accessTokenCookie = getCookie(accessTokenCookieName)

  if (accessTokenCookie != null && accessTokenCookie !== '') {
    return { data: accessTokenCookie }
  }

  const { data, error } = await refreshAccessToken()

  if (error != null) {
    return { error }
  }

  return { data: data.accessToken }
}

export const testSession: TestSession = async () => {
  let accessToken = getCookie(accessTokenCookieName)

  const redirectToLogin = () => {
    window.location.replace(routes.login)
  }

  if (accessToken == null || accessToken.length < 1) {
    const { data, error } = await refreshAccessToken()

    if (error != null) {
      return {
        data: null,
        error: { message: error.message, action: redirectToLogin }
      }
    }

    return {
      error: null,
      data: {
        user: data
      }
    }
  }

  const res = await fetch(`${apiBaseUrl}/api/auth/testsession`, {
    method: 'POST',
    headers: {
      'Content-type': 'application/json',
      Authorization: accessToken
    },
    credentials: 'include'
  })

  try {
    const textResponse = await res.text()
    const json = JSON.parse(textResponse)

    if (json.status === 'success') {
      return {
        error: null,
        data: {
          user: json.data
        }
      }
    }

    if (res.status !== 401) {
      return {
        data: null,
        error: { message: String(json.error), action: redirectToLogin }
      }
    }

    const { data, error } = await refreshAccessToken()

    if (error !== null) {
      return {
        data: null,
        error: { message: String(json.error), action: redirectToLogin }
      }
    }

    return {
      error: null,
      data: {
        user: data
      }
    }
  } catch (error) {
    return {
      error: {
        message: 'Unexpected format response',
        action: redirectToLogin
      },
      data: null
    }
  }
}

export const login: AuthLogin = async ({ username, password }) => {
  const res = await fetch(`${apiBaseUrl}/api/auth/login`, {
    method: 'POST',
    headers: {
      'Content-type': 'application/json'
    },
    body: JSON.stringify({
      usuario: username,
      clave: password
    }),
    credentials: 'include'
  })

  const accessToken = res.headers.get('Authorization')

  if (accessToken != null) {
    setCookie(accessTokenCookieName, accessToken, 1)
  }

  try {
    const textResponse = await res.text()
    const json = JSON.parse(textResponse)

    if (json.status !== 'success') {
      return { data: null, error: { message: String(json.error) } }
    }

    return {
      error: null,
      data: {
        message: 'Bienvenido ' + json.data.usuario,
        action: () => {
          window.location.replace(routes.dashboard)
        }
      }
    }
  } catch (error) {
    return {
      error: {
        message: 'Unexpected format response'
      },
      data: null
    }
  }
}

export const logout: AuthLogout = async () => {
  let accessToken = getCookie(accessTokenCookieName)

  const redirectToLogin = () => {
    window.location.replace(routes.login)
  }

  if (accessToken == null || accessToken.length < 1) {
    return {
      data: null,
      error: { message: 'Invalid session', action: redirectToLogin }
    }
  }

  const res = await fetch(`${apiBaseUrl}/api/auth/logout`, {
    method: 'POST',
    headers: {
      'Content-type': 'application/json',
      Authorization: accessToken
    },
    credentials: 'include'
  })

  try {
    const textResponse = await res.text()
    const json = JSON.parse(textResponse)

    console.log(json)

    if (json.status !== 'success') {
      return {
        data: null,
        error: {
          message: String(json.error ?? 'Unexpected error'),
          action: redirectToLogin
        }
      }
    }

    deleteCookie(accessTokenCookieName)

    return {
      error: null,
      data: {
        message: json.message,
        action: redirectToLogin
      }
    }
  } catch (error) {
    return {
      error: {
        message: 'Unexpected format response',
        action: () => {}
      },
      data: null
    }
  }
}
