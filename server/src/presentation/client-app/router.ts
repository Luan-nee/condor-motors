import express, { Router } from 'express'
import path from 'node:path'

export class ClientAppRouter {
  static get routes() {
    const router = Router()

    router.use(express.static(path.join(process.cwd(), 'client-build')))

    router.get('*', (_, res) => {
      res.sendFile(path.join(process.cwd(), 'client-build', 'index.html'))
    })

    return router
  }
}
