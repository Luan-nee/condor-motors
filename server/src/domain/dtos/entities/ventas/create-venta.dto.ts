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
  public documento?: {
    enviarCliente?: boolean
    fechaEmision?: string
    horaEmision?: string
  }

  constructor({
    observaciones,
    tipoDocumentoId,
    detalles,
    monedaId,
    metodoPagoId,
    clienteId,
    empleadoId,
    documento
  }: CreateVentaDto) {
    this.observaciones = observaciones
    this.tipoDocumentoId = tipoDocumentoId
    this.detalles = detalles
    this.monedaId = monedaId
    this.metodoPagoId = metodoPagoId
    this.clienteId = clienteId
    this.empleadoId = empleadoId
    this.documento = documento
  }

  static validate(input: any): [string?, CreateVentaDto?] {
    const result = createVentaValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    const { data } = result

    return [undefined, new CreateVentaDto(data)]
  }
}
