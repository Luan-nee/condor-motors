import { createSucursalValidator } from '@/domain/validators/entities/sucursal/sucursal.validator'

export class CreateSucursalDto {
  public nombre: string
  public direccion?: string | null
  public sucursalCentral: boolean
  public serieFactura?: string | null
  public numeroFacturaInicial?: number | null
  public serieBoleta?: string | null
  public numeroBoletaInicial?: number | null
  public codigoEstablecimiento?: string | null

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
