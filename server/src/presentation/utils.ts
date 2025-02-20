import { isProduction, refreshTokenCookieName } from '@/consts'
import { serialize } from 'cookie'

export const serializeRefreshTokenCookie = ({ token }: { token: string }) => {
  const refresTokenCookie = serialize(refreshTokenCookieName, token, {
    httpOnly: true,
    secure: isProduction,
    sameSite: 'strict',
    maxAge: 1000 * 60 * 60 * 24 * 7,
    path: '/'
  })

  return refresTokenCookie
}

export const serializeAccessToken = ({ token }: { token: string }) => {
  const bearerAccessToken = 'Bearer ' + token

  return bearerAccessToken
}
