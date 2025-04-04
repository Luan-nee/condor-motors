import { updateClienteValidator } from '@/domain/validators/entities/clientes/cliente.validator'

export class UpdateClienteDto {
  public numeroDocumento?: string | null
  public denominacion?: string
  public direccion?: string | null
  public correo?: string | null
  public telefono?: string | null

  private constructor({
    numeroDocumento,
    denominacion,
    direccion,
    correo,
    telefono
  }: UpdateClienteDto) {
    this.numeroDocumento = numeroDocumento
    this.denominacion = denominacion
    this.direccion = direccion
    this.correo = correo
    this.telefono = telefono
  }
  private static isEmptyUpdate(
    data: UpdateClienteDto
  ): data is Record<string, never> {
    return Object.values(data).every((valor) => valor === undefined)
  }

  static create(input: any): [string?, UpdateClienteDto?] {
    const result = updateClienteValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    if (this.isEmptyUpdate(result.data)) {
      return ['No se recibio informacion para actualizar', undefined]
    }

    return [undefined, new UpdateClienteDto(result.data)]
  }
}
