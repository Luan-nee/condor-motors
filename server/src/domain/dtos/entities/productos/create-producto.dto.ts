import { createProductoValidator } from '@/domain/validators/entities/productos/producto.validator'

export class CreateProductoDto {
  public sku: string
  public nombre: string
  public descripcion?: string
  public maxDiasSinReabastecer?: number
  public unidadId: number
  public categoriaId: number
  public marcaId: number
  public precioBase?: number
  public precioMayorista?: number
  public precioOferta?: number
  public stock?: number
  public sucursalId: number

  private constructor({
    sku,
    nombre,
    descripcion,
    maxDiasSinReabastecer,
    unidadId,
    categoriaId,
    marcaId,
    precioBase,
    precioMayorista,
    precioOferta,
    stock,
    sucursalId
  }: CreateProductoDto) {
    this.sku = sku
    this.nombre = nombre
    this.descripcion = descripcion
    this.maxDiasSinReabastecer = maxDiasSinReabastecer
    this.unidadId = unidadId
    this.categoriaId = categoriaId
    this.marcaId = marcaId
    this.precioBase = precioBase
    this.precioMayorista = precioMayorista
    this.precioOferta = precioOferta
    this.stock = stock
    this.sucursalId = sucursalId
  }

  static create(input: any, sucursalId: number): [string?, CreateProductoDto?] {
    const result = createProductoValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    const { data } = result

    return [
      undefined,
      new CreateProductoDto({
        ...data,
        sucursalId
      })
    ]
  }
}
