import type { NextFunction, Request, Response } from 'express'

export class LoggerMiddleware {
  static requests = (req: Request, _res: Response, next: NextFunction) => {
    const resource = 'http://' + req.headers.host + req.baseUrl + req.url

    // eslint-disable-next-line no-console
    console.log(`
      __________________________________________________\n
      Request logs -------- | ${new Date().toISOString()}\n
      START - - - - - - - - - - - - - - - - - - - - - --\n
      resource: ${resource}\n
      headers: ${JSON.stringify(req.headers)}\n
      - - - - - - - - - - - - - - - - - Specific headers\n
      access-control-request-method: ${
        req.headers['access-control-request-method']
      }\n
      access-control-request-headers: ${
        req.headers['access-control-request-headers']
      }\n
      - - - - - - - - - - - - - - - - - - - - - - Others\n
      body: ${req.body}\n
      cookies: ${req.cookies}\n
      params: ${JSON.stringify(req.params)}\n
      query: ${JSON.stringify(req.query)}\n
      -- - - - - - - - - - - - - - - - - - - - - - - END\n
      __________________________________________________\n
      `)
    next()
  }
}
