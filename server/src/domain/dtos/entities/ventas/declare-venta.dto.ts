import { declareVentaValidator } from '@/domain/validators/entities/ventas/venta.validator'

export class DeclareVentaDto {
  public enviarCliente: boolean

  constructor({ enviarCliente }: DeclareVentaDto) {
    this.enviarCliente = enviarCliente
  }

  static validate(input: any): [string?, DeclareVentaDto?] {
    const result = declareVentaValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    const { data } = result

    return [undefined, new DeclareVentaDto(data)]
  }
}
