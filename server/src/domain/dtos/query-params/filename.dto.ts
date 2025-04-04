import { paramsFilenameValidator } from '@/domain/validators/query-params/query-params.validator'

export class FilenameDto {
  public filename: string

  private constructor({ filename }: FilenameDto) {
    this.filename = filename
  }

  static create(input: any): [string?, FilenameDto?] {
    const result = paramsFilenameValidator(input)

    if (!result.success) {
      return ['Nombre de archivo inválido', undefined]
    }

    return [undefined, new FilenameDto(result.data)]
  }
}
