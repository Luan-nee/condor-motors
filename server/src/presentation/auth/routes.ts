import { BcryptAdapter } from '@/config/bcrypt'
import { CookieTokenAdapter } from '@/config/cookie'
import { JwtAdapter } from '@/config/jwt'
import { AuthController } from '@presentation/auth/controller'
import { Router } from 'express'
import { AuthMiddleware } from '@/presentation/middlewares/auth.middleware'

export class AuthRoutes {
  static get routes() {
    const router = Router()

    const authController = new AuthController(
      JwtAdapter,
      BcryptAdapter,
      CookieTokenAdapter
    )

    router.post(
      '/register',
      [AuthMiddleware.requests],
      authController.registerUser
    )

    router.post('/login', authController.loginUser)

    router.post('/refresh', authController.refreshToken)

    return router
  }
}
