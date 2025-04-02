import { API_URL } from 'astro:env/client'

export const accessTokenCookieName = 'access_token'
export const apiBaseUrl = API_URL

export const fileFieldName = 'app_file' as const

export const fileTypeValues = {
  apk: 'apk',
  desktopApp: 'desktop-app'
} as const
