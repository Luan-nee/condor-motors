import { createProductoValidator } from '@/domain/validators/entities/productos/producto.validator'

export class CreateProductoDto {
  public sku: string
  public nombre: string
  public descripcion?: string
  public maxDiasSinReabastecer?: number
  public unidadId: number
  public categoriaId: number
  public marcaId: number

  private constructor({
    sku,
    nombre,
    descripcion,
    maxDiasSinReabastecer,
    unidadId,
    categoriaId,
    marcaId
  }: CreateProductoDto) {
    this.sku = sku
    this.nombre = nombre
    this.descripcion = descripcion
    this.maxDiasSinReabastecer = maxDiasSinReabastecer
    this.unidadId = unidadId
    this.categoriaId = categoriaId
    this.marcaId = marcaId
  }

  static create(input: any): [string?, CreateProductoDto?] {
    const result = createProductoValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    return [undefined, new CreateProductoDto(result.data)]
  }
}
