import { createClienteValidator } from '@/domain/validators/entities/clientes/cliente.validator'

export class CreateClienteDto {
  public nombresApellidos?: string
  public dni?: string
  public razonSocial?: string
  public ruc?: string
  public telefono?: string
  public correo: string
  public tipoPersonaId: number

  private constructor({
    nombresApellidos,
    dni,
    razonSocial,
    ruc,
    telefono,
    correo,
    tipoPersonaId
  }: CreateClienteDto) {
    this.nombresApellidos = nombresApellidos
    this.dni = dni
    this.razonSocial = razonSocial
    this.ruc = ruc
    this.telefono = telefono
    this.correo = correo
    this.tipoPersonaId = tipoPersonaId
  }

  static create(input: any): [string?, CreateClienteDto?] {
    const result = createClienteValidator(input)
    if (!result.success) {
      return [result.error.message, undefined]
    }
    return [undefined, new CreateClienteDto(result.data)]
  }
}
