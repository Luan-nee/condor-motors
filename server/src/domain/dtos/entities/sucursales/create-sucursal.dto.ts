import { createSucursalValidator } from '@domain/validators/entities/sucursal/create-sucursal.validator'

export class CreateSucursalDto {
  public nombre: string
  public ubicacion?: string
  public sucursalCentral: boolean

  private constructor({
    nombre,
    ubicacion,
    sucursalCentral
  }: CreateSucursalDto) {
    this.nombre = nombre
    this.ubicacion = ubicacion
    this.sucursalCentral = sucursalCentral
  }

  static create(input: any): [string?, CreateSucursalDto?] {
    const result = createSucursalValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    return [undefined, new CreateSucursalDto(result.data)]
  }
}
