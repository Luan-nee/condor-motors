import { createTransferenciaInvValidator } from '@/domain/validators/entities/transferencias-inventario/transferencia-inventario.validator'

export class CreateTransferenciaInvDto {
  public sucursalDestinoId: number
  public items: Array<{
    cantidad: number
    productoId: number
  }>

  constructor({
    sucursalDestinoId,
    items: detalleVenta
  }: CreateTransferenciaInvDto) {
    this.sucursalDestinoId = sucursalDestinoId
    this.items = detalleVenta
  }

  static create(input: any): [string?, CreateTransferenciaInvDto?] {
    const result = createTransferenciaInvValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    return [undefined, new CreateTransferenciaInvDto(result.data)]
  }
}
