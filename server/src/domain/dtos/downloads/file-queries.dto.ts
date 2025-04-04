import { fileQueriesValidator } from '@/domain/validators/downloads/file-queries.validator'

export class FileQueriesDto {
  public exp: number
  public tk: string

  private constructor({ exp, tk }: FileQueriesDto) {
    this.exp = exp
    this.tk = tk
  }

  static create(input: any): [string?, FileQueriesDto?] {
    const result = fileQueriesValidator(input)

    if (!result.success) {
      return ['Invalida queries', undefined]
    }

    return [undefined, new FileQueriesDto(result.data)]
  }
}
