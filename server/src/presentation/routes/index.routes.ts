import { type Response, Router } from 'express'
import { CustomResponse } from '@/core/responses/custom.response'
import { ApiRoutes } from '@/presentation/routes/api.routes'
import { StaticRoutes } from '@/presentation/routes/static.routes'
import { DownloadsRoutes } from '@/presentation/downloads/routes'
import { envs } from '@/config/envs'

export class AppRoutes {
  static get routes() {
    const router = Router()

    if (envs.SERVE_PUBLIC_STORAGE) {
      router.use('/', StaticRoutes.routes)
    }

    router.use('/downloads', DownloadsRoutes.routes)

    router.use('/api', ApiRoutes.routes)

    router.use((_req, res: Response) => {
      CustomResponse.notFound({ res })
    })

    return router
  }
}
