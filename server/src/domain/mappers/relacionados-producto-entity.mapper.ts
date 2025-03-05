import type { RelacionadosProductoEntity } from '@/types/schemas'

export class RelacionadosProductoEntityMapper {
  static fromObject(input: RelacionadosProductoEntity) {
    return {
      unidadNombre: input.unidadNombre,
      categoriaNombre: input.categoriaNombre,
      marcaNombre: input.marcaNombre
    }
  }
}
