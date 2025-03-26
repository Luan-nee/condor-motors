import { declareVentaValidator } from '@/domain/validators/entities/facturacion/facturacion.validator'

export class DeclareVentaDto {
  public enviarCliente: boolean
  public ventaId: number

  constructor({ enviarCliente, ventaId }: DeclareVentaDto) {
    this.enviarCliente = enviarCliente
    this.ventaId = ventaId
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
