import { createProformaVentaValidator } from '@/domain/validators/entities/proformas-venta/proforma-venta.validator'

export class CreateProformaVentaDto {
  public nombre?: string | null
  public empleadoId: number
  public clienteId?: number | null
  public detalles: Array<{
    productoId: number
    cantidad: number
  }>

  constructor({
    nombre,
    detalles,
    empleadoId,
    clienteId
  }: CreateProformaVentaDto) {
    this.nombre = nombre
    this.detalles = detalles
    this.empleadoId = empleadoId
    this.clienteId = clienteId
  }

  static validate(input: any): [string?, CreateProformaVentaDto?] {
    const result = createProformaVentaValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    const { data } = result

    return [undefined, new CreateProformaVentaDto(data)]
  }
}
