import { createClienteValidator } from '@/domain/validators/entities/clientes/cliente.validator'

export class CreateClienteDto {
  public tipoDocumentoId: number
  public numeroDocumento: string
  public denominacion: string
  public direccion?: string
  public correo?: string
  public telefono?: string

  private constructor({
    tipoDocumentoId,
    numeroDocumento,
    denominacion,
    direccion,
    correo,
    telefono
  }: CreateClienteDto) {
    this.tipoDocumentoId = tipoDocumentoId
    this.numeroDocumento = numeroDocumento
    this.denominacion = denominacion
    this.direccion = direccion
    this.correo = correo
    this.telefono = telefono
  }

  static create(input: any): [string?, CreateClienteDto?] {
    const result = createClienteValidator(input)
    if (!result.success) {
      return [result.error.message, undefined]
    }
    return [undefined, new CreateClienteDto(result.data)]
  }
}
