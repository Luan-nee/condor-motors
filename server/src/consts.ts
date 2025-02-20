import { envs } from '@/config/envs'

export const refreshTokenCookieName = 'refresh_token'
export const isProduction = envs.NODE_ENV === 'production'
