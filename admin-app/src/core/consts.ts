export const accessTokenCookieName = 'access_token'

export const apiBaseUrl = import.meta.env.PUBLIC_API_URL
export const assetsBaseUrl = import.meta.env.PUBLIC_ASSETS_BASE_URL
export const baseUrl = import.meta.env.BASE_URL

export const fileFieldName = 'app_file' as const

export const fileTypeValues = {
  apk: 'apk',
  desktopApp: 'desktop-app',
  certificate: 'certificate'
} as const

const maxFileSizeMB = import.meta.env.MAX_UPLOAD_FILE_SIZE_MB
export const maxFileSizeAllowed = Number(maxFileSizeMB) * 1024 * 1024
