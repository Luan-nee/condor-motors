import { createSucursalValidator } from '@/domain/validators/entities/sucursal/sucursal.validator'

export class CreateSucursalDto {
  public nombre: string
  public direccion?: string
  public sucursalCentral: boolean
  public serieFactura?: string
  public numeroFacturaInicial?: number
  public serieBoleta?: string
  public numeroBoletaInicial?: number
  public codigoEstablecimiento?: string

  private constructor({
    nombre,
    direccion,
    sucursalCentral,
    serieFactura,
    numeroFacturaInicial,
    serieBoleta,
    numeroBoletaInicial,
    codigoEstablecimiento
  }: CreateSucursalDto) {
    this.nombre = nombre
    this.direccion = direccion
    this.sucursalCentral = sucursalCentral
    this.serieFactura = serieFactura
    this.numeroFacturaInicial = numeroFacturaInicial
    this.serieBoleta = serieBoleta
    this.numeroBoletaInicial = numeroBoletaInicial
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
