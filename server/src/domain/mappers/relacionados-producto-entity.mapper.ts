import { CustomError } from '@/core/errors/custom.error'
import type { RelacionadosProductoEntity } from '@/types/schemas'

export class RelacionadosProductoEntityMapper {
  static fromObject(input: any): RelacionadosProductoEntity {
    const { unidadNombre, categoriaNombre, marcaNombre } = input

    if (unidadNombre === undefined) {
      throw CustomError.internalServer('Missing unidadNombre')
    }
    if (categoriaNombre === undefined) {
      throw CustomError.internalServer('Missing categoriaNombre')
    }
    if (marcaNombre === undefined) {
      throw CustomError.internalServer('Missing marcaNombre')
    }

    return {
      unidadNombre,
      categoriaNombre,
      marcaNombre
    }
  }
}
