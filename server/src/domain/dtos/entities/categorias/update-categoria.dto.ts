import { updateCategoriaValidator } from '@/domain/validators/entities/categorias/categoria.validator'

export class UpdateCategoriaDto {
  public nombre?: string
  public descripcion?: string

  private constructor({ nombre, descripcion }: UpdateCategoriaDto) {
    this.nombre = nombre
    this.descripcion = descripcion
  }

  private static isEmptyUpdate(
    data: UpdateCategoriaDto
  ): data is Record<string, never> {
    return Object.values(data).every((value) => value === undefined)
  }

  static create(input: any): [string?, UpdateCategoriaDto?] {
    const result = updateCategoriaValidator(input)
    if (!result.success) {
      return [result.error.message, undefined]
    }

    if (this.isEmptyUpdate(result.data)) {
      return ['No se recibio informacion para actualizar ', undefined]
    }

    return [undefined, new UpdateCategoriaDto(result.data)]
  }
}
