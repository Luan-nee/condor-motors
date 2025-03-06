import { paramsNumericIdValidator } from '@/domain/validators/query-params/query-params.validator'

export class NumericIdDto {
  public id: number

  private constructor({ id }: NumericIdDto) {
    this.id = id
  }

  static create(input: any): [string?, NumericIdDto?] {
    const result = paramsNumericIdValidator(input)

    if (!result.success) {
      return ['Id inválido', undefined]
    }

    return [undefined, new NumericIdDto(result.data)]
  }
}
