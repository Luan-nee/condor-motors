import { paramsDoubleNumericIdValidator } from '@/domain/validators/query-params/query-params.validator'

export class DoubleNumericIdDto {
  public id: number
  public secondId: number

  private constructor({ id, secondId: sencondId }: DoubleNumericIdDto) {
    this.id = id
    this.secondId = sencondId
  }

  static create(input: any): [string?, DoubleNumericIdDto?] {
    const result = paramsDoubleNumericIdValidator(input)

    if (!result.success) {
      return ['Id inválido', undefined]
    }

    return [undefined, new DoubleNumericIdDto(result.data)]
  }
}
