import { isProduction, refreshTokenCookieName } from '@/consts'
import type {
  bearerAccessTokenType,
  refreshAccessTokenType,
  refreshTokenCookieType
} from '@/types/config'
import { serialize } from 'cookie'

export class CookieTokenAdapter {
  static refreshTokenCookie: refreshTokenCookieType = ({ refreshToken }) => {
    const refreshTokenCookie = serialize(refreshTokenCookieName, refreshToken, {
      httpOnly: true,
      secure: isProduction,
      sameSite: 'strict',
      maxAge: 1000 * 60 * 60 * 24 * 7,
      path: '/'
    })

    return refreshTokenCookie
  }

  static bearerAccessToken: bearerAccessTokenType = ({ accessToken }) => {
    const bearerAccessToken = 'Bearer ' + accessToken

    return bearerAccessToken
  }

  static refreshAccessToken: refreshAccessTokenType = ({
    accessToken,
    refreshToken
  }) => ({
    bearerAccessToken: this.bearerAccessToken({ accessToken }),
    refresTokenCookie: this.refreshTokenCookie({ refreshToken })
  })
}
