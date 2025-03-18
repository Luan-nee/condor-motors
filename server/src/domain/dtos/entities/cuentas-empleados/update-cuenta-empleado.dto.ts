import { updateCuentaEmpleadoValidator } from '@/domain/validators/entities/cuentas-empleados/cuenta-empleado.validator'

export class UpdateCuentaEmpleadoDto {
  public usuario?: string
  public clave?: string
  public rolCuentaEmpleadoId?: number

  private constructor({
    usuario,
    clave,
    rolCuentaEmpleadoId
  }: UpdateCuentaEmpleadoDto) {
    this.usuario = usuario
    this.clave = clave
    this.rolCuentaEmpleadoId = rolCuentaEmpleadoId
  }

  private static isEmptyUpdate(
    data: UpdateCuentaEmpleadoDto
  ): data is Record<string, never> {
    return Object.values(data).every((value) => value === undefined)
  }

  static create(input: any): [string?, UpdateCuentaEmpleadoDto?] {
    const result = updateCuentaEmpleadoValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    if (this.isEmptyUpdate(result.data)) {
      return ['No se recibio informacion para actualizar', undefined]
    }

    return [undefined, new UpdateCuentaEmpleadoDto(result.data)]
  }
}
