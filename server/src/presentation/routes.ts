import { CustomResponse } from '@/core/responses/custom.response'
import { ApiRoutes } from '@presentation/api.routes'
import { type Response, Router } from 'express'

export class AppRoutes {
  static get routes() {
    const router = Router()

    router.use('/api', ApiRoutes.routes)

    router.use((_req, res: Response) => {
      CustomResponse.notFound({ res })
    })

    return router
  }
}
