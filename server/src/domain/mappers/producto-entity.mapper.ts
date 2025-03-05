import { CustomError } from '@/core/errors/custom.error'
import type { ProductoEntity } from '@/types/schemas'
import { RelacionadosProductoEntityMapper } from './relacionados-producto-entity.mapper'

export class ProductoEntityMapper {
  static fromObject(input: any): ProductoEntity {
    const {
      id,
      sku,
      nombre,
      descripcion,
      maxDiasSinReabastecer,
      unidadId,
      categoriaId,
      marcaId,
      fechaCreacion,
      fechaActualizacion,
      relacionados
    } = input

    if (id === undefined) {
      throw CustomError.internalServer('Missing id')
    }
    if (sku === undefined) {
      throw CustomError.internalServer('Missing sku')
    }
    if (nombre === undefined) {
      throw CustomError.internalServer('Missing nombre')
    }
    if (descripcion === undefined) {
      throw CustomError.internalServer('Missing descripcion')
    }
    if (unidadId === undefined) {
      throw CustomError.internalServer('Missing unidadId')
    }
    if (categoriaId === undefined) {
      throw CustomError.internalServer('Missing categoriaId')
    }
    if (marcaId === undefined) {
      throw CustomError.internalServer('Missing marcaId')
    }
    if (fechaCreacion === undefined) {
      throw CustomError.internalServer('Missing fechaCreacion')
    }
    if (fechaActualizacion === undefined) {
      throw CustomError.internalServer('Missing fechaActualizacion')
    }

    const mappedRelacionados =
      RelacionadosProductoEntityMapper.fromObject(relacionados)

    return {
      id,
      nombre,
      descripcion,
      sku,
      maxDiasSinReabastecer,
      unidadId,
      categoriaId,
      marcaId,
      relacionados: mappedRelacionados,
      fechaCreacion,
      fechaActualizacion
    }
  }
}
