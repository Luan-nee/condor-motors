import { addProductoValidator } from '@/domain/validators/entities/productos/producto.validator'

export class AddProductoDto {
  public precioCompra: number
  public precioVenta: number
  public precioOferta?: number
  public stock: number

  private constructor({
    precioCompra,
    precioVenta,
    precioOferta,
    stock
  }: AddProductoDto) {
    this.precioCompra = precioCompra
    this.precioVenta = precioVenta
    this.precioOferta = precioOferta
    this.stock = stock
  }

  static create(input: any): [string?, AddProductoDto?] {
    const result = addProductoValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    const { data } = result

    return [undefined, new AddProductoDto(data)]
  }
}
