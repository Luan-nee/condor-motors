import express, { type Router } from 'express'

interface ServerOptions {
  port?: number
  routes: Router
}

export class Server {
  public readonly app = express()
  private readonly port: number
  private readonly routes: Router

  constructor(options: ServerOptions) {
    const { port = 3000, routes } = options

    this.port = port
    this.routes = routes
  }

  start() {
    this.app.use(express.json())

    this.app.disable('x-powered-by')

    this.app.use(this.routes)

    this.app.listen(this.port, () => {
      // eslint-disable-next-line no-console
      console.log(`Server running on port: http://localhost:${this.port}`)
    })
  }
}
