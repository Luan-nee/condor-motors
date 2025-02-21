import { CustomError } from '@domain/errors/custom.error'

export class SucursalEntityMapper {
  static sucursalEntityFromObject(input: any): SucursalEntity {
    const { id, nombre, ubicacion, sucursalCentral, fechaRegistro } = input

    if (id === undefined) {
      throw CustomError.badRequest('Missing id')
    }
    if (nombre === undefined) {
      throw CustomError.badRequest('Missing nombre')
    }
    if (sucursalCentral === undefined) {
      throw CustomError.badRequest('Missing sucursalCentral')
    }
    if (fechaRegistro === undefined) {
      throw CustomError.badRequest('Missing fechaRegistro')
    }

    const mappedUbicacion = ubicacion === null ? undefined : ubicacion

    return {
      id,
      nombre,
      ubicacion: mappedUbicacion,
      sucursalCentral,
      fechaRegistro
    }
  }
}
