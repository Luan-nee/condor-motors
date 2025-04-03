import { deleteCookie, getCookie, setCookie } from '@/core/lib/cookies'
import { accessTokenCookieName } from '@/core/consts'
import { customFetch, httpRequest, resToData } from '@/core/lib/network'
import { backendRoutes, routes } from '@/core/routes'

export const refreshAccessToken: RefreshAccessToken = async () => {
  const { res, fetchError } = await customFetch(backendRoutes.refresh, {
    method: 'POST',
    headers: {
      'Content-type': 'application/json'
    },
    credentials: 'include'
  })

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
  const { data, error } = await httpRequest<TestUserSuccess>(
    backendRoutes.testSession,
    (accessToken) => ({
      method: 'POST',
      headers: {
        'Content-type': 'application/json',
        Authorization: accessToken
      },
      credentials: 'include'
    })
  )

  if (error != null) {
    return {
      error: {
        message: error.message,
        action: () => {
          window.location.replace(routes.login)
        }
      }
    }
  }

  return { data }
}

export const login: AuthLogin = async ({ username, password }) => {
  const { res, fetchError } = await customFetch(backendRoutes.login, {
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

  if (fetchError != null) {
    return { error: fetchError }
  }

  const accessToken = res.headers.get('Authorization')

  if (accessToken != null) {
    setCookie(accessTokenCookieName, accessToken, 15)
  }

  const { data, error } = await resToData(res)

  if (error != null) {
    return { error }
  }

  return {
    data: {
      message: 'Bienvenido ' + data.usuario,
      action: () => {
        window.location.replace(routes.dashboard)
      }
    }
  }
}

export const logout: AuthLogout = async () => {
  const { error } = await httpRequest(backendRoutes.logout, (accessToken) => ({
    method: 'POST',
    headers: {
      'Content-type': 'application/json',
      Authorization: accessToken
    },
    credentials: 'include'
  }))

  const redirectToLogin = () => {
    window.location.replace(routes.login)
  }

  if (error != null) {
    return {
      error: {
        message: error.message,
        action: redirectToLogin
      }
    }
  }

  deleteCookie(accessTokenCookieName)

  return {
    data: {
      message: 'Sesión terminada exitosamente',
      action: redirectToLogin
    }
  }
}
