import { entradaInventarioValidator } from '@/domain/validators/entities/inventario/inventario.validator'

export class EntradaInventarioDto {
  public productoId: number
  public cantidad: number

  constructor({ productoId, cantidad }: EntradaInventarioDto) {
    this.productoId = productoId
    this.cantidad = cantidad
  }

  static validate(input: any): [string?, EntradaInventarioDto?] {
    const result = entradaInventarioValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    return [undefined, new EntradaInventarioDto(result.data)]
  }
}
