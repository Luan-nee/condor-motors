import { cancelVentaValidator } from '@/domain/validators/entities/ventas/venta.validator'

export class CancelVentaDto {
  public motivoAnulado: string

  constructor({ motivoAnulado }: CancelVentaDto) {
    this.motivoAnulado = motivoAnulado
  }

  static validate(input: any): [string?, CancelVentaDto?] {
    const result = cancelVentaValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    return [undefined, new CancelVentaDto(result.data)]
  }
}
