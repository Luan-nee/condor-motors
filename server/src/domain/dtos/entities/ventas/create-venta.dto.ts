import { createVentaValidator } from '@/domain/validators/entities/ventas/venta.validator'

export class CreateVentaDto {
  public observaciones?: string
  public tipoDocumentoId: number
  public detalles: Array<{
    productoId: number
    cantidad: number
    tipoTaxId: number
  }>
  public monedaId?: number
  public metodoPagoId?: number
  public clienteId: number
  public empleadoId: number
  public fechaEmision?: string
  public horaEmision?: string

  constructor({
    observaciones,
    tipoDocumentoId,
    detalles,
    monedaId,
    metodoPagoId,
    clienteId,
    empleadoId,
    fechaEmision,
    horaEmision
  }: CreateVentaDto) {
    this.observaciones = observaciones
    this.tipoDocumentoId = tipoDocumentoId
    this.detalles = detalles
    this.monedaId = monedaId
    this.metodoPagoId = metodoPagoId
    this.clienteId = clienteId
    this.empleadoId = empleadoId
    this.fechaEmision = fechaEmision
    this.horaEmision = horaEmision
  }

  private static validateDuplicatedProducts(createVentaDto: CreateVentaDto) {
    const productoIds = new Set<number>()
    const duplicateProductoIds = new Set<number>()

    for (const { productoId } of createVentaDto.detalles) {
      if (productoIds.has(productoId)) {
        duplicateProductoIds.add(productoId)
      } else {
        productoIds.add(productoId)
      }
    }

    if (duplicateProductoIds.size > 0) {
      return `Existen productos duplicados en los detalles: ${[...duplicateProductoIds].join(', ')}`
    }
  }

  static validate(input: any): [string?, CreateVentaDto?] {
    const result = createVentaValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    const { data } = result

    const duplicatedProductsErrorMessage = this.validateDuplicatedProducts(data)

    if (duplicatedProductsErrorMessage !== undefined) {
      return [duplicatedProductsErrorMessage, undefined]
    }

    return [undefined, new CreateVentaDto(data)]
  }
}
