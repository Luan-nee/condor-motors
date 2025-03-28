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

  private static validateDuplicatedProducts(
    createTransferenciaInvDto: CreateTransferenciaInvDto
  ) {
    const productoIds = new Set<number>()
    const duplicateProductIds = new Set<number>()

    for (const { productoId } of createTransferenciaInvDto.items) {
      if (productoIds.has(productoId)) {
        duplicateProductIds.add(productoId)
      } else {
        productoIds.add(productoId)
      }
    }

    if (duplicateProductIds.size > 0) {
      return `Existen productos duplicados en los items: ${[...duplicateProductIds].join(', ')}`
    }
  }

  static create(input: any): [string?, CreateTransferenciaInvDto?] {
    const result = createTransferenciaInvValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    const { data } = result

    const duplicatedProductsErrorMessage = this.validateDuplicatedProducts(data)

    if (duplicatedProductsErrorMessage !== undefined) {
      return [duplicatedProductsErrorMessage, undefined]
    }

    return [undefined, new CreateTransferenciaInvDto(data)]
  }
}
