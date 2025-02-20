import { BcryptAdapter } from '@/config/bcrypt'
import { JwtAdapter } from '@/config/jwt'
import { AuthController } from '@presentation/auth/controller'
import { Router } from 'express'

export class AuthRoutes {
  static get routes() {
    const router = Router()

    const authController = new AuthController(JwtAdapter, BcryptAdapter)

    router.post('/register', authController.registerUser)

    router.post('/login', authController.loginUser)

    router.post('/refresh', authController.refreshToken)

    return router
  }
}
