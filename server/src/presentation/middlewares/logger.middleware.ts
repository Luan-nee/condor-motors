/* eslint-disable no-console */
import type { NextFunction, Request, Response } from 'express'

export class LoggerMiddleware {
  static requests = (req: Request, _res: Response, next: NextFunction) => {
    const resource = 'http://' + req.headers.host + req.baseUrl + req.url

    console.log('__________________________________________________')
    console.log('Request logs -------- | ', new Date().toISOString())
    console.log('START - - - - - - - - - - - - - - - - - - - - - --')
    console.log('resource:', resource)
    console.log('headers:', JSON.stringify(req.headers))
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
    console.log('params:', JSON.stringify(req.params))
    console.log('query:', JSON.stringify(req.query))
    console.log('-- - - - - - - - - - - - - - - - - - - - - - - END')
    console.log('__________________________________________________')
    next()
  }
}
