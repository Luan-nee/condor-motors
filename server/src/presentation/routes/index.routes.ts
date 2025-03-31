import { type Response, Router } from 'express'
import { CustomResponse } from '@/core/responses/custom.response'
import { ApiRoutes } from '@/presentation/routes/api.routes'
import { StaticRoutes } from '@/presentation/routes/static.routes'

export class AppRoutes {
  static get routes() {
    const router = Router()

    router.use('/api', ApiRoutes.routes)

    router.use('/', StaticRoutes.routes)

    router.use((_req, res: Response) => {
      CustomResponse.notFound({ res })
    })

    return router
  }
}
