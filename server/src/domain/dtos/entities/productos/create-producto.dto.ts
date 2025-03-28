import { createProductoValidator } from '@/domain/validators/entities/productos/producto.validator'

export class CreateProductoDto {
  public nombre: string
  public descripcion?: string
  public maxDiasSinReabastecer?: number
  public stockMinimo?: number
  public cantidadMinimaDescuento?: number
  public cantidadGratisDescuento?: number
  public porcentajeDescuento?: number
  public colorId: number
  public categoriaId: number
  public marcaId: number
  public precioCompra: number
  public precioVenta: number
  public precioOferta?: number
  public stock: number
  public liquidacion: boolean

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
    stock,
    liquidacion
  }: CreateProductoDto) {
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
    this.liquidacion = liquidacion
  }

  static create(input: any): [string?, CreateProductoDto?] {
    const result = createProductoValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    const { data } = result

    return [undefined, new CreateProductoDto(data)]
  }
}
