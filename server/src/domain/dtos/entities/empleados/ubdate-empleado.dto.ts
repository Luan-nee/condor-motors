import { updateEmpleadoValidator } from '@/domain/validators/entities/empleados/empleado.validator'

export class UpdateEmpleadoDto {
  public nombre?: string
  public apellido?: string
  public edad?: number
  public dni?: string
  public horaInicioJornada?: string
  public horaFinJornada?: string
  public sueldo?: number
  public sucursalId?: number

  private constructor({
    nombre,
    apellido,
    edad,
    dni,
    horaInicioJornada,
    horaFinJornada,
    sueldo,
    sucursalId
  }: UpdateEmpleadoDto) {
    this.nombre = nombre
    this.apellido = apellido
    this.edad = edad
    this.dni = dni
    this.horaInicioJornada = horaInicioJornada
    this.horaFinJornada = horaFinJornada
    this.sueldo = sueldo
    this.sucursalId = sucursalId
  }

  static create(input: any): [string?, UpdateEmpleadoDto?] {
    const result = updateEmpleadoValidator(input)
    if (!result.success) {
      return [result.error.message, undefined]
    }

    if (
      result.data.nombre === undefined &&
      result.data.apellidos === undefined &&
      result.data.edad === undefined &&
      result.data.dni === undefined &&
      result.data.horaInicioJornada === undefined &&
      result.data.horaFinJornada === undefined &&
      result.data.sueldo === undefined &&
      result.data.sucursalId === undefined
    ) {
      return ['No se recibio informacion para actualizar', undefined]
    }

    return [undefined, new UpdateEmpleadoDto(result.data)]
  }
}
