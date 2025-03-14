import { updateProductoValidator } from '@/domain/validators/entities/productos/producto.validator'

export class UpdateProductoDto {
  public nombre?: string
  public descripcion?: string
  public maxDiasSinReabastecer?: number
  public stockMinimo?: number
  public cantidadMinimaDescuento?: number
  public cantidadGratisDescuento?: number
  public porcentajeDescuento?: number
  public colorId?: number
  public categoriaId?: number
  public marcaId?: number
  public precioCompra?: number
  public precioVenta?: number
  public precioOferta?: number
  public stock?: number

  private constructor({
    nombre,
    descripcion,
    maxDiasSinReabastecer,
    stockMinimo,
    cantidadMinimaDescuento,
    cantidadGratisDescuento,
    porcentajeDescuento,
    colorId,
    categoriaId,
    marcaId,
    precioCompra,
    precioVenta,
    precioOferta,
    stock
  }: UpdateProductoDto) {
    this.nombre = nombre
    this.descripcion = descripcion
    this.maxDiasSinReabastecer = maxDiasSinReabastecer
    this.stockMinimo = stockMinimo
    this.cantidadMinimaDescuento = cantidadMinimaDescuento
    this.cantidadGratisDescuento = cantidadGratisDescuento
    this.porcentajeDescuento = porcentajeDescuento
    this.colorId = colorId
    this.categoriaId = categoriaId
    this.marcaId = marcaId
    this.precioCompra = precioCompra
    this.precioVenta = precioVenta
    this.precioOferta = precioOferta
    this.stock = stock
  }

  private static isEmptyUpdate(
    data: UpdateProductoDto
  ): data is Record<string, never> {
    return Object.values(data).every((value) => value === undefined)
  }

  static create(input: any): [string?, UpdateProductoDto?] {
    const result = updateProductoValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    if (this.isEmptyUpdate(result.data)) {
      return ['No se recibio informacion para actualizar', undefined]
    }

    return [undefined, new UpdateProductoDto(result.data)]
  }
}
