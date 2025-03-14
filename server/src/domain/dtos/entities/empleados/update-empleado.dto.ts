import { updateEmpleadoValidator } from '@/domain/validators/entities/empleados/empleado.validator'

export class UpdateEmpleadoDto {
  public nombre?: string
  public apellidos?: string
  public activo?: boolean
  public dni?: string
  public celular?: string
  public horaInicioJornada?: string
  public horaFinJornada?: string
  public fechaContratacion?: string
  public sueldo?: number
  public sucursalId?: number

  private constructor({
    nombre,
    apellidos,
    activo,
    dni,
    celular,
    horaInicioJornada,
    horaFinJornada,
    fechaContratacion,
    sueldo,
    sucursalId
  }: UpdateEmpleadoDto) {
    this.nombre = nombre
    this.apellidos = apellidos
    this.activo = activo
    this.dni = dni
    this.celular = celular
    this.horaInicioJornada = horaInicioJornada
    this.horaFinJornada = horaFinJornada
    this.fechaContratacion = fechaContratacion
    this.sueldo = sueldo
    this.sucursalId = sucursalId
  }

  private static isEmptyUpdate(
    data: UpdateEmpleadoDto
  ): data is Record<string, never> {
    return Object.values(data).every((value) => value === undefined)
  }

  static create(input: any): [string?, UpdateEmpleadoDto?] {
    const result = updateEmpleadoValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    if (this.isEmptyUpdate(result.data)) {
      return ['No se recibio informacion para actualizar', undefined]
    }

    return [undefined, new UpdateEmpleadoDto(result.data)]
  }
}
