import { updateEmpleadoValidator } from '@/domain/validators/entities/empleados/empleado.validator'

export class UpdateEmpleadoDto {
  public nombre?: string
  public apellidos?: string
  public activo?: boolean
  public dni?: string | null
  public celular?: string | null
  public horaInicioJornada?: string | null
  public horaFinJornada?: string | null
  public fechaContratacion?: string | null
  public sueldo?: number | null
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

  static create(
    input: any,
    fileSize: number | undefined
  ): [string?, UpdateEmpleadoDto?] {
    const result = updateEmpleadoValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    if (this.isEmptyUpdate(result.data) && fileSize == null) {
      return ['No se recibio informacion para actualizar', undefined]
    }

    return [undefined, new UpdateEmpleadoDto(result.data)]
  }
}
