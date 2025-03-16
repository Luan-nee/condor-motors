import { createCategoriaValidator } from '@/domain/validators/entities/categorias/categoria.validator'

export class CreateCategoriaDto {
  public nombre: string
  public descripcion?: string

  private constructor({ nombre, descripcion }: CreateCategoriaDto) {
    this.nombre = nombre
    this.descripcion = descripcion
  }
  static create(input: any): [string?, CreateCategoriaDto?] {
    const resultado = createCategoriaValidator(input)

    if (!resultado.success) {
      return [resultado.error.message, undefined]
    }
    return [undefined, new CreateCategoriaDto(resultado.data)]
  }
}
