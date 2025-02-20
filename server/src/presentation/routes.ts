import { ApiRoutes } from '@presentation/api.routes'
// import { ClientAppRouter } from '@presentation/client-app/router'
import { type Request, type Response, Router } from 'express'
import { AuthMiddleware } from './middlewares/auth.middleware'

export class AppRoutes {
  static get routes() {
    const router = Router()

    router.use('/api', ApiRoutes.routes)

    router.get(
      '/protected',
      AuthMiddleware.requests,
      (_req: Request, res: Response) => {
        res.status(200).json('You have access to this protected route :D')
      }
    )

    // router.use(ClientAppRouter.routes)

    router.use((_req, res: Response) => {
      res.status(404).contentType('text/plain; charset=utf-8').send('Not Found')
    })

    return router
  }
}
