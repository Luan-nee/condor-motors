import { Router } from 'express'
import { DownloadsController } from './controller'
import { JwtAdapter } from '@/config/jwt'
import { envs } from '@/config/envs'

export class DownloadsRoutes {
  static get routes() {
    const router = Router()

    const downloadsController = new DownloadsController(
      JwtAdapter,
      envs.PRIVATE_STORAGE_PATH
    )

    router.get('/:filename', downloadsController.apkDesktopApp)

    return router
  }
}
