import { updateSucursalValidator } from '@/domain/validators/entities/sucursal/sucursal.validator'

export class UpdateSucursalDto {
  public nombre?: string
  public direccion?: string
  public sucursalCentral?: boolean

  private constructor({
    nombre,
    direccion,
    sucursalCentral
  }: UpdateSucursalDto) {
    this.nombre = nombre
    this.direccion = direccion
    this.sucursalCentral = sucursalCentral
  }

  static create(input: any): [string?, UpdateSucursalDto?] {
    const result = updateSucursalValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    if (
      result.data.nombre === undefined &&
      result.data.direccion === undefined &&
      result.data.sucursalCentral === undefined
    ) {
      return [
        '{"message": "No se recibió información para actualizar"}',
        undefined
      ]
    }

    return [undefined, new UpdateSucursalDto(result.data)]
  }
}
