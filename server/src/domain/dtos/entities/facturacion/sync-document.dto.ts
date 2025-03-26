import { syncDocumentValidator } from '@/domain/validators/entities/facturacion/facturacion.validator'

export class SyncDocumentDto {
  public ventaId: number

  constructor({ ventaId }: SyncDocumentDto) {
    this.ventaId = ventaId
  }

  static validate(input: any): [string?, SyncDocumentDto?] {
    const result = syncDocumentValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    const { data } = result

    return [undefined, new SyncDocumentDto(data)]
  }
}
