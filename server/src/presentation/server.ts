import { ErrorMiddleware } from '@presentation/middlewares/error.middleware'
import express, { type Router } from 'express'
import { CookieMiddleware } from './middlewares/cookie-parser.middleware'
import { LoggerMiddleware } from './middlewares/logger.middleware'
import { CorsMiddleware } from './middlewares/cors.middleware'

interface ServerOptions {
  host?: string
  port?: number
  routes: Router
}

export class Server {
  public readonly app = express()
  private readonly port: number
  private readonly host: string
  private readonly routes: Router

  constructor(options: ServerOptions) {
    const { port = 3000, host = 'localhost', routes } = options

    this.port = port
    this.host = host
    this.routes = routes
  }

  start() {
    this.app.use(express.json())
    this.app.disable('x-powered-by')
    this.app.use(CookieMiddleware.requests)
    this.app.use(CorsMiddleware.requests)
    this.app.use(LoggerMiddleware.requests)

    this.app.use(this.routes)

    this.app.use(ErrorMiddleware.requests)

    this.app.listen(this.port, this.host, () => {
      // eslint-disable-next-line no-console
      console.log(`Server running on port: http://${this.host}:${this.port}`)
    })
  }
}
