import { loginUserValidator } from '@/domain/validators/auth/login-user.validator'

export class LoginUserDto {
  public usuario: string
  public clave: string

  private constructor({ usuario, clave }: LoginUserDto) {
    this.usuario = usuario
    this.clave = clave
  }

  static create(input: any): [string?, LoginUserDto?] {
    const result = loginUserValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    return [undefined, new LoginUserDto(result.data)]
  }
}
