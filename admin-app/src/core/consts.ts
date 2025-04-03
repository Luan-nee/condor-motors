export const accessTokenCookieName = 'access_token'

export const apiBaseUrl = import.meta.env.PUBLIC_API_URL

export const baseUrl = import.meta.env.BASE_URL

export const fileFieldName = 'app_file' as const

export const fileTypeValues = {
  apk: 'apk',
  desktopApp: 'desktop-app'
} as const

export const maxFileSizeAllowed = 150 * 1024 * 1024
