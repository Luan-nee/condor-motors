import { updateSucursalValidator } from '@/domain/validators/entities/sucursal/sucursal.validator'

export class UpdateSucursalDto {
  public nombre?: string
  public direccion?: string | null
  public sucursalCentral?: boolean
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
  }: UpdateSucursalDto) {
    this.nombre = nombre
    this.direccion = direccion
    this.sucursalCentral = sucursalCentral
    this.serieFactura = serieFactura
    this.numeroFacturaInicial = numeroFacturaInicial
    this.serieBoleta = serieBoleta
    this.numeroBoletaInicial = numeroBoletaInicial
    this.codigoEstablecimiento = codigoEstablecimiento
  }

  private static isEmptyUpdate(
    data: UpdateSucursalDto
  ): data is Record<string, never> {
    return Object.values(data).every((value) => value === undefined)
  }

  static create(input: any): [string?, UpdateSucursalDto?] {
    const result = updateSucursalValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    if (this.isEmptyUpdate(result.data)) {
      return ['No se recibio informacion para actualizar', undefined]
    }

    return [undefined, new UpdateSucursalDto(result.data)]
  }
}
