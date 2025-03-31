import { Router } from 'express'
import path from 'path'

export class AppRoutes {
  static get routes() {
    const router = Router()

    router.get('/', (_req, res) => {
      res.sendFile(path.join(process.cwd(), 'storage/app', 'index.html'))
    })

    return router
  }
}
