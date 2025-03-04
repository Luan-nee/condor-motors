import { createEmpleadoValidator } from '@/domain/validators/entities/empleados/empleado.validator'

export class CreateEmpleadoDto {
  public nombre: string
  public apellidos: string
  public edad?: number
  public dni: string
  public horaInicioJornada: string
  public horaFinJornada: string
  public sueldo?: number
  public sucursalId: number
  public fechaContratacion?: string
  private constructor({
    nombre,
    apellidos,
    edad,
    dni,
    horaInicioJornada,
    horaFinJornada,
    fechaContratacion,
    sueldo,
    sucursalId
  }: CreateEmpleadoDto) {
    this.nombre = nombre
    this.apellidos = apellidos
    this.edad = edad
    this.dni = dni
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
