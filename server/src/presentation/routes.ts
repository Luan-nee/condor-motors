import { CustomError } from '@/core/errors/custom.error'
import { handleError } from '@/core/errors/handle.error'
import { ApiRoutes } from '@presentation/api.routes'
import { type Response, Router } from 'express'

export class AppRoutes {
  static get routes() {
    const router = Router()

    router.use('/api', ApiRoutes.routes)

    router.use((_req, res: Response) => {
      const notFound = CustomError.notFound('Not found')
      handleError(notFound, res)
    })

    return router
  }
}
