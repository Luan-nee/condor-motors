import { updateReservasProductosValidator } from '@/domain/validators/entities/reservas-productos/reservasProductos.validator'

export class UpdateReservasProductosDto {
  public descripcion?: string
  public detallesReserva?: Array<{
    nombreProducto: string
    precioCompra: number
    precioVenta: number
    cantidad: number
    total: number
  }>
  public montoAdelantado?: number
  public fechaRecojo?: string
  public sucursalId?: number

  private constructor({
    descripcion,
    detallesReserva,
    montoAdelantado,
    fechaRecojo,
    sucursalId
  }: UpdateReservasProductosDto) {
    this.descripcion = descripcion
    this.detallesReserva = detallesReserva
    this.montoAdelantado = montoAdelantado
    this.fechaRecojo = fechaRecojo
    this.sucursalId = sucursalId
  }

  private static isEmptyUpdate(
    data: UpdateReservasProductosDto
  ): data is Record<string, never> {
    return Object.values(data).every((value) => value === undefined)
  }

  static create(input: any): [string?, UpdateReservasProductosDto?] {
    const result = updateReservasProductosValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    if (this.isEmptyUpdate(result.data)) {
      return ['No se recibio informacion para actualizar', undefined]
    }

    return [undefined, new UpdateReservasProductosDto(result.data)]
  }
}
