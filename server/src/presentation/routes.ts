import { ApiRoutes } from '@presentation/api.routes'
// import { ClientAppRouter } from '@presentation/client-app/router'
import { type Response, Router } from 'express'

export class AppRoutes {
  static get routes() {
    const router = Router()

    router.use('/api', ApiRoutes.routes)

    // router.use(ClientAppRouter.routes)

    router.use((_req, res: Response) => {
      res.status(404).contentType('text/plain; charset=utf-8').send('Not Found')
    })

    return router
  }
}
