import { createEmpleadoValidator } from '@/domain/validators/entities/empleados/empleado.validator'

export class CreateEmpleadoDto {
  public nombre: string
  public apellidos: string
  public activo: boolean
  public dni: string
  public celular?: string
  public horaInicioJornada?: string
  public horaFinJornada?: string
  public fechaContratacion?: string
  public sueldo?: number
  public sucursalId: number

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
  }: CreateEmpleadoDto) {
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

  static create(input: any): [string?, CreateEmpleadoDto?] {
    const resultado = createEmpleadoValidator(input)

    if (!resultado.success) {
      return [resultado.error.message, undefined]
    }

    return [undefined, new CreateEmpleadoDto(resultado.data)]
  }
}
