import { createTransferenciaInventarioValidator } from '@/domain/validators/entities/transferenciaInventario/transferenciaInventario.validator'

export class CreateTransferenciaInventarioDto {
  public empleadoId?: number
  public sucursalOrigenId?: number
  public sucursalDestinoId: number
  public detalleVenta: {
    cantidad: number
    productoId: number
    transferenciaInventarioId: number
  }

  constructor({
    empleadoId,
    sucursalOrigenId,
    sucursalDestinoId,
    detalleVenta
  }: CreateTransferenciaInventarioDto) {
    this.empleadoId = empleadoId
    this.sucursalOrigenId = sucursalOrigenId
    this.sucursalDestinoId = sucursalDestinoId
    this.detalleVenta = detalleVenta
  }

  static create(input: any): [string?, CreateTransferenciaInventarioDto?] {
    const resultado = createTransferenciaInventarioValidator(input)
    if (!resultado.success) {
      return [resultado.error.message, undefined]
    }
    return [undefined, new CreateTransferenciaInventarioDto(resultado.data)]
  }
}
