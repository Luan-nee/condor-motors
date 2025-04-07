import { Router, static as ExpressStatic } from 'express'
import { envs } from '@/config/envs'

export class StaticRoutes {
  static get routes() {
    const router = Router()

    router.use(
      '/',
      ExpressStatic(envs.PUBLIC_STORAGE_PATH, {
        setHeaders: (_res, filePath) => {
          if (filePath.endsWith('.gitignore')) {
            return false
          }
        }
      })
    )

    return router
  }
}
