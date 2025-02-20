import type { Encryptor, TokenAuthenticator } from '@/interfaces'
import { LoginUserDto } from '@domain/dtos/auth/login-user.dto'
import { RegisterUserDto } from '@domain/dtos/auth/register-user.dto'
import { handleError } from '@domain/errors/handle.error'
import { LoginUser } from '@domain/use-cases/auth/login-user.use-case'
import { RegisterUser } from '@domain/use-cases/auth/register-user.use-case'
import type { Request, Response } from 'express'

export class AuthController {
  constructor(
    private readonly tokenAuthenticator: TokenAuthenticator,
    private readonly encryptor: Encryptor
  ) {}

  registerUser = async (req: Request, res: Response) => {
    const [error, registerUserDto] = RegisterUserDto.create(req.body)
    if (error !== undefined || registerUserDto === undefined) {
      res.status(400).json({ error: JSON.parse(error ?? '') })
      return
    }
    const registerUser = new RegisterUser(
      this.tokenAuthenticator,
      this.encryptor
    )

    try {
      const user = await registerUser.execute(registerUserDto)

      res.status(200).json(user)
    } catch (error) {
      handleError(error, res)
    }
  }

  loginUser = async (req: Request, res: Response) => {
    const [error, loginUserDto] = LoginUserDto.create(req.body)

    if (error !== undefined || loginUserDto === undefined) {
      res.status(400).json({ error: JSON.parse(error ?? '') })
      return
    }

    const loginUser = new LoginUser(this.tokenAuthenticator, this.encryptor)

    try {
      const user = await loginUser.execute(loginUserDto)

      res.status(200).json(user)
    } catch (error) {
      handleError(error, res)
    }
  }

  // authorize = (req: Request, res: Response) => {}
}
