import { cancelDocumentValidator } from '@/domain/validators/entities/facturacion/facturacion.validator'

export class CancelDocumentDto {
  public ventaId: number

  constructor({ ventaId }: CancelDocumentDto) {
    this.ventaId = ventaId
  }

  static validate(input: any): [string?, CancelDocumentDto?] {
    const result = cancelDocumentValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    const { data } = result

    return [undefined, new CancelDocumentDto(data)]
  }
}
