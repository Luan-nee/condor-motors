import { Router } from 'express'
import { DownloadsController } from './controller'
import { JwtAdapter } from '@/config/jwt'

export class DownloadsRoutes {
  static get routes() {
    const router = Router()

    const downloadsController = new DownloadsController(JwtAdapter)

    router.get('/:filename', downloadsController.apkDesktopApp)

    return router
  }
}
