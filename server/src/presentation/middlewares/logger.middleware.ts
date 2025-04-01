/* eslint-disable no-console */
import { envs } from '@/config/envs'
import { CustomLogger } from '@/config/logger'
import { isProduction, logsDestination } from '@/consts'
import type { NextFunction, Request, Response } from 'express'

export class LoggerMiddleware {
  static requests = (req: Request, res: Response, next: NextFunction) => {
    if (envs.LOGS === logsDestination.none) {
      next()
      return
    }

    const { protocol, headers, baseUrl, url } = req
    const { host } = headers
    const resource = `${protocol}://${host}${baseUrl}${url}`
    const startTime = Date.now()

    res.on('finish', () => {
      const duration = Date.now() - startTime
      if (!isProduction) {
        console.log('==================================================')
        console.log('Request logs ---------- |', new Date().toISOString())
        console.log('START - - - - - - - - - - - - - - - - - - - - - --')
        console.log('resource:', resource)
        console.log('method:', req.method)
        console.log('origin:', req.ip)
        console.log('status:', res.statusCode)
        console.log('response time:', `${duration}ms`)
        console.log('headers:', req.headers)
        console.log('- - - - - - - - - - - - - - - - - Specific headers')
        console.log(
          'access-control-request-method:',
          req.headers['access-control-request-method']
        )
        console.log(
          'access-control-request-headers:',
          req.headers['access-control-request-headers']
        )
        console.log('- - - - - - - - - - - - - - - - - - - - - - Others')
        console.log('body:', req.body)
        console.log('cookies:', req.cookies)
        console.log('params:', req.params)
        console.log('query:', req.query)
        console.log('-- - - - - - - - - - - - - - - - - - - - - - - END')
        console.log('==================================================')
      }

      if (envs.LOGS === logsDestination.filesystem) {
        const ip = req.ip ?? null
        const user = req.authPayload ?? { id: null }
        const message = `${req.method} ${resource} ${req.protocol.toUpperCase()}/${req.httpVersion} ${res.statusCode} ${duration}ms`
        const meta = { ip, user }

        CustomLogger.info(message, meta)
      }
    })

    next()
  }
}
