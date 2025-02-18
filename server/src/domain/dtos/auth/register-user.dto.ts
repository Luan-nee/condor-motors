import { registerUserValidator } from '@/domain/validators/auth/register-user.validator'

export class RegisterUserDto {
  public usuario: string
  public clave: string
  public rolCuentaEmpleadoId: number
  public empleadoId: number

  private constructor({
    usuario,
    clave,
    rolCuentaEmpleadoId,
    empleadoId
  }: RegisterUserDto) {
    this.usuario = usuario
    this.clave = clave
    this.rolCuentaEmpleadoId = rolCuentaEmpleadoId
    this.empleadoId = empleadoId
  }

  static create(input: any): [string?, RegisterUserDto?] {
    const result = registerUserValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    return [undefined, new RegisterUserDto(result.data)]
  }
}
