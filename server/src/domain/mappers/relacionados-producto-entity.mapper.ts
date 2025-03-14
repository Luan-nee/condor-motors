import type { RelacionadosProductoEntity } from '@/types/schemas'

export class RelacionadosProductoEntityMapper {
  static fromObject(input: RelacionadosProductoEntity) {
    return {
      colorNombre: input.colorNombre,
      categoriaNombre: input.categoriaNombre,
      marcaNombre: input.marcaNombre
    }
  }
}
