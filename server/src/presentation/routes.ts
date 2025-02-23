import { ApiRoutes } from '@presentation/api.routes'
import { type Response, Router } from 'express'

export class AppRoutes {
  static get routes() {
    const router = Router()

    router.use('/api', ApiRoutes.routes)

    router.use((_req, res: Response) => {
      res.status(404).json({ message: 'Not Found' })
    })

    return router
  }
}
