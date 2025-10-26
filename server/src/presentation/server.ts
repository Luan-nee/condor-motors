import { ErrorMiddleware } from '@presentation/middlewares/error.middleware'
import express, { type Router } from 'express'
import { CookieMiddleware } from './middlewares/cookie-parser.middleware'
import { LoggerMiddleware } from './middlewares/logger.middleware'
import { CorsMiddleware } from './middlewares/cors.middleware'
import { access, constants, mkdir } from 'node:fs/promises'
import { logger } from '@/config/logger'

interface ServerOptions {
  host?: string
  port?: number
  routes: Router
  privateStoragePath: string
  publicStoragePath: string
}

export class Server {
  public readonly app = express()
  private readonly port: number
  private readonly host: string
  private readonly routes: Router
  private readonly privateStoragePath: string
  private readonly publicStoragePath: string

  constructor(options: ServerOptions) {
    const {
      port = 3000,
      host = 'localhost',
      routes,
      privateStoragePath,
      publicStoragePath
    } = options

    this.port = port
    this.host = host
    this.routes = routes
    this.privateStoragePath = privateStoragePath
    this.publicStoragePath = publicStoragePath
  }

  async checkDirectory(dirPath: string) {
    try {
      await access(dirPath, constants.R_OK | constants.W_OK)
    } catch (error: any) {
      if (error?.code === 'ENOENT') {
        await mkdir(dirPath, { recursive: true })
        return
      }

      logger.error({
        message: `Error al verificar o crear el directorio ${dirPath}:`,
        context: { error }
      })

      if (error instanceof Error) {
        throw error
      }
    }
  }

  async setupStorage() {
    await this.checkDirectory(this.privateStoragePath)
    await this.checkDirectory(this.publicStoragePath)
  }

  start() {
    const start = process.hrtime.bigint()

    this.app.use(express.json())
    this.app.disable('x-powered-by')
    this.app.use(CookieMiddleware.requests)
    this.app.use(LoggerMiddleware.requests)
    this.app.use(CorsMiddleware.requests)

    this.app.use(this.routes)

    this.app.use(ErrorMiddleware.requests)

    this.setupStorage()
      .then()
      .catch((error: unknown) => {
        if (error instanceof Error) {
          throw error
        }

        logger.error({
          message: 'Unexpected error',
          context: { error }
        })
        throw new Error('Unexpected error')
      })

    this.app.listen(this.port, this.host, () => {
      const end = process.hrtime.bigint()
      const duration = Number(end - start) / 1_000_000

      logger.info({
        message: `Server running on port: http://${this.host}:${this.port}`,
        context: { duration }
      })
    })
  }
}
