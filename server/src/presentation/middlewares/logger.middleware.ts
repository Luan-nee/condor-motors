import { logger } from '@/config/logger'
import type { NextFunction, Request, Response } from 'express'

export class LoggerMiddleware {
  static requests = (req: Request, res: Response, next: NextFunction) => {
    const start = process.hrtime.bigint()

    const { protocol, headers, baseUrl, url } = req
    const { host } = headers
    const resource = `${protocol}://${host}${baseUrl}${url}`

    res.on('finish', () => {
      const end = process.hrtime.bigint()
      const duration = Number(end - start) / 1_000_000

      logger.info({
        message: 'Request completed',
        context: {
          resource,
          method: req.method,
          ip: req.ip,
          statusCode: res.statusCode,
          durationMs: duration
        }
      })
    })

    next()
  }
}
