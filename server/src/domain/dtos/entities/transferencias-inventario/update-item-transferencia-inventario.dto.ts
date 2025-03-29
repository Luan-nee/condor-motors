import { updateItemTransferenciaInvValidator } from '@/domain/validators/entities/transferencias-inventario/transferencia-inventario.validator'

export class UpdateItemTransferenciaInvDto {
  public cantidad: number

  constructor({ cantidad }: UpdateItemTransferenciaInvDto) {
    this.cantidad = cantidad
  }

  static create(input: any): [string?, UpdateItemTransferenciaInvDto?] {
    const result = updateItemTransferenciaInvValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    const { data } = result

    return [undefined, new UpdateItemTransferenciaInvDto(data)]
  }
}
