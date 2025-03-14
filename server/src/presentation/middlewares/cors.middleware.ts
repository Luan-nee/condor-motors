import { envs } from '@/config/envs'
import { CustomError } from '@/core/errors/custom.error'
import cors from 'cors'

export class CorsMiddleware {
  static readonly allowedOrigins = envs.ALLOWED_ORIGINS

  static readonly requests = cors({
    origin: (origin, callback) => {
      if (
        typeof origin !== 'string' ||
        CorsMiddleware.allowedOrigins.includes(origin)
      ) {
        callback(null, true)
      } else {
        callback(CustomError.corsError(undefined, this.allowedOrigins), false)
      }
    }
  })
}
