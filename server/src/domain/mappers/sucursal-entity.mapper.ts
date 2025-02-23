import type { SucursalEntity } from '@/types/schemas'
import { CustomError } from '@domain/errors/custom.error'

export class SucursalEntityMapper {
  static sucursalEntityFromObject(input: any): SucursalEntity {
    const {
      id,
      nombre,
      direccion,
      sucursalCentral,
      fechaCreacion,
      fechaActualizacion
    } = input

    if (id === undefined) {
      throw CustomError.badRequest('Missing id')
    }
    if (nombre === undefined) {
      throw CustomError.badRequest('Missing nombre')
    }
    if (sucursalCentral === undefined) {
      throw CustomError.badRequest('Missing sucursalCentral')
    }
    if (fechaCreacion === undefined) {
      throw CustomError.badRequest('Missing fechaCreacion')
    }
    if (fechaActualizacion === undefined) {
      throw CustomError.badRequest('Missing fechaActualizacion')
    }

    return {
      id,
      nombre,
      direccion,
      sucursalCentral,
      fechaCreacion,
      fechaActualizacion
    }
  }
}
