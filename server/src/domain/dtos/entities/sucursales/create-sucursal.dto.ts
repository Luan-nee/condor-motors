import { createSucursalValidator } from '@/domain/validators/entities/sucursal/sucursal.validator'

export class CreateSucursalDto {
  public nombre: string
  public direccion?: string
  public sucursalCentral: boolean
  public serieFacturaSucursal?: string
  public serieBoletaSucursal?: string
  public codigoEstablecimiento?: string

  private constructor({
    nombre,
    direccion,
    sucursalCentral,
    serieFacturaSucursal,
    serieBoletaSucursal,
    codigoEstablecimiento
  }: CreateSucursalDto) {
    this.nombre = nombre
    this.direccion = direccion
    this.sucursalCentral = sucursalCentral
    this.serieFacturaSucursal = serieFacturaSucursal
    this.serieBoletaSucursal = serieBoletaSucursal
    this.codigoEstablecimiento = codigoEstablecimiento
  }

  static create(input: any): [string?, CreateSucursalDto?] {
    const result = createSucursalValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    return [undefined, new CreateSucursalDto(result.data)]
  }
}
