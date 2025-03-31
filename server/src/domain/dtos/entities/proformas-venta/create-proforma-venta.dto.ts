import { createProformaVentaValidator } from '@/domain/validators/entities/proformas-venta/proforma-venta.validator'

export class CreateProformaVentaDto {
  public nombre?: string | null
  public empleadoId: number
  public clienteId?: number | null
  public detalles: Array<{
    productoId: number
    cantidad: number
  }>

  constructor({
    nombre,
    detalles,
    empleadoId,
    clienteId
  }: CreateProformaVentaDto) {
    this.nombre = nombre
    this.detalles = detalles
    this.empleadoId = empleadoId
    this.clienteId = clienteId
  }

  private static validateDuplicatedProducts(
    createProformaVentaDto: CreateProformaVentaDto
  ) {
    const productoIds = new Set<number>()
    const duplicateProductoIds = new Set<number>()

    for (const { productoId } of createProformaVentaDto.detalles) {
      if (productoIds.has(productoId)) {
        duplicateProductoIds.add(productoId)
      } else {
        productoIds.add(productoId)
      }
    }

    if (duplicateProductoIds.size > 0) {
      return `Existen productos duplicados en los detalles: ${[...duplicateProductoIds].join(', ')}`
    }
  }

  static validate(input: any): [string?, CreateProformaVentaDto?] {
    const result = createProformaVentaValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    const { data } = result

    const duplicatedProductsErrorMessage = this.validateDuplicatedProducts(data)

    if (duplicatedProductsErrorMessage !== undefined) {
      return [duplicatedProductsErrorMessage, undefined]
    }

    return [undefined, new CreateProformaVentaDto(data)]
  }
}
