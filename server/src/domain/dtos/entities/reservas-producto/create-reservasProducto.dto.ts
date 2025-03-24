import { CreateReservasProductoValidator } from '@/domain/validators/entities/reservas-productos/reservasProductos.validator'

export class CreateReservasProductoDto {
  public descripcion: string
  public detallesReserva: {
    nombreProducto: string
    precioCompra: number
    precioVenta: number
    cantidad: number
    total: number
  }
  public montoAdelantado: number
  public fechaRecojo: string
  public clienteId: number
  public sucursalId: number

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
