import { updateProductoValidator } from '@/domain/validators/entities/productos/producto.validator'

export class UpdateProductoDto {
  public nombre?: string
  public descripcion?: string | null
  public maxDiasSinReabastecer?: number | null
  public stockMinimo?: number | null
  public cantidadMinimaDescuento?: number | null
  public cantidadGratisDescuento?: number | null
  public porcentajeDescuento?: number | null
  public colorId?: number
  public categoriaId?: number
  public marcaId?: number
  public precioCompra?: number
  public precioVenta?: number
  public precioOferta?: number | null
  public liquidacion?: boolean

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
    liquidacion
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
    this.liquidacion = liquidacion
  }

  private static isEmptyUpdate(
    data: UpdateProductoDto
  ): data is Record<string, never> {
    return Object.values(data).every((value) => value === undefined)
  }

  static create(
    input: any,
    fileSize: number | undefined
  ): [string?, UpdateProductoDto?] {
    const result = updateProductoValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    if (this.isEmptyUpdate(result.data) && fileSize == null) {
      return ['No se recibio informacion para actualizar', undefined]
    }

    const { data } = result

    if (
      data.cantidadGratisDescuento != null &&
      data.cantidadGratisDescuento > 0
    ) {
      data.porcentajeDescuento = null
    }

    if (data.porcentajeDescuento != null && data.porcentajeDescuento > 0) {
      data.cantidadGratisDescuento = null
    }

    return [undefined, new UpdateProductoDto(data)]
  }
}
