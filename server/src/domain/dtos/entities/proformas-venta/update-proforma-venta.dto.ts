import { updateProformaVentaValidator } from '@/domain/validators/entities/proformas-venta/proforma-venta.validator'

export class UpdateProformaVentaDto {
  public nombre?: string
  public detalles?: Array<{
    productoId: number
    cantidad: number
  }>

  constructor({ nombre, detalles }: UpdateProformaVentaDto) {
    this.nombre = nombre
    this.detalles = detalles
  }

  private static isEmptyUpdate(
    data: UpdateProformaVentaDto
  ): data is Record<string, never> {
    return Object.values(data).every((value) => value === undefined)
  }

  static validate(input: any): [string?, UpdateProformaVentaDto?] {
    const result = updateProformaVentaValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    if (this.isEmptyUpdate(result.data)) {
      return ['No se recibio informacion para actualizar', undefined]
    }

    return [undefined, new UpdateProformaVentaDto(result.data)]
  }
}
