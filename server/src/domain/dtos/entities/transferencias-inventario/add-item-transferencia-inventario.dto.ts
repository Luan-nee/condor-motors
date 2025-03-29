import { addItemTransferenciaInvValidator } from '@/domain/validators/entities/transferencias-inventario/transferencia-inventario.validator'

export class AddItemTransferenciaInvDto {
  public items: Array<{
    cantidad: number
    productoId: number
  }>

  constructor({ items }: AddItemTransferenciaInvDto) {
    this.items = items
  }

  private static validateDuplicatedProducts(
    addItemTransferenciaInvDto: AddItemTransferenciaInvDto
  ) {
    const productoIds = new Set<number>()
    const duplicateProductIds = new Set<number>()

    for (const { productoId } of addItemTransferenciaInvDto.items) {
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

  static create(input: any): [string?, AddItemTransferenciaInvDto?] {
    const result = addItemTransferenciaInvValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    const { data } = result

    const duplicatedProductsErrorMessage = this.validateDuplicatedProducts(data)

    if (duplicatedProductsErrorMessage !== undefined) {
      return [duplicatedProductsErrorMessage, undefined]
    }

    return [undefined, new AddItemTransferenciaInvDto(data)]
  }
}
