import { envs } from '@/config/envs'
import { CustomError } from '@/core/errors/custom.error'
import cors from 'cors'

export class CorsMiddleware {
  static readonly allowedOrigins = envs.ALLOWED_ORIGINS

  static readonly requests = cors({
    exposedHeaders: ['Authorization'],
    origin: (origin, callback) => {
      if (origin === undefined) {
        callback(null, true)
        return
      }

      if (
        CorsMiddleware.allowedOrigins.includes('*') ||
        CorsMiddleware.allowedOrigins.includes(origin)
      ) {
        callback(null, true)
        return
      }

      callback(
        CustomError.corsError(undefined, CorsMiddleware.allowedOrigins),
        false
      )
    }
  })
}
