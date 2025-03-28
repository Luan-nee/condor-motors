import { enviarTransferenciaInvValidator } from '@/domain/validators/entities/transferencias-inventario/transferencia-inventario.validator'

export class EnviarTransferenciaInvDto {
  public sucursalOrigenId: number

  constructor({ sucursalOrigenId }: EnviarTransferenciaInvDto) {
    this.sucursalOrigenId = sucursalOrigenId
  }

  static create(input: any): [string?, EnviarTransferenciaInvDto?] {
    const result = enviarTransferenciaInvValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    const { data } = result

    return [undefined, new EnviarTransferenciaInvDto(data)]
  }
}
