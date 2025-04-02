import { Router, static as ExpressStatic } from 'express'
import path from 'path'

export class AppRoutes {
  static get routes() {
    const router = Router()

    router.use(
      '/',
      ExpressStatic(path.join(process.cwd(), 'storage/app/'), {
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
