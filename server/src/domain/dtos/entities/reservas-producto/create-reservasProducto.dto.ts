import { CreateReservasProductoValidator } from '@/domain/validators/entities/reservas-productos/reservasProductos.validator'

export class CreateReservasProductoDto {
  public descripcion?: string | null
  public detallesReserva: Array<{
    nombreProducto: string
    precioCompra: number
    precioVenta: number
    cantidad: number
    total: number
  }>
  public montoAdelantado: number
  public fechaRecojo?: string | null
  public clienteId: number
  public sucursalId?: number | null

  private constructor({
    descripcion,
    detallesReserva,
    montoAdelantado,
    fechaRecojo,
    clienteId,
    sucursalId
  }: CreateReservasProductoDto) {
    this.descripcion = descripcion
    this.detallesReserva = detallesReserva
    this.montoAdelantado = montoAdelantado
    this.fechaRecojo = fechaRecojo
    this.clienteId = clienteId
    this.sucursalId = sucursalId
  }

  static create(input: any): [string?, CreateReservasProductoDto?] {
    const resultado = CreateReservasProductoValidator(input)

    if (!resultado.success) {
      return [resultado.error.message, undefined]
    }

    return [undefined, new CreateReservasProductoDto(resultado.data)]
  }
}
