import { Router, static as ExpressStatic } from 'express'
import path from 'path'

export class StaticRoutes {
  static get routes() {
    const router = Router()

    router.use(
      '/',
      ExpressStatic(path.join(process.cwd(), 'storage/public/'), {
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
