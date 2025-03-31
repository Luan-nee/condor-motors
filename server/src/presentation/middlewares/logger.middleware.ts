/* eslint-disable no-console */
import { isProduction } from '@/consts'
import type { NextFunction, Request, Response } from 'express'

export class LoggerMiddleware {
  static requests = (req: Request, res: Response, next: NextFunction) => {
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
    })

    next()
  }
}
