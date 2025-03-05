import type { SucursalEntity } from '@/types/schemas'

export class SucursalEntityMapper {
  static fromObject(input: SucursalEntity) {
    const parsedId = String(input.id)

    return {
      id: parsedId,
      nombre: input.nombre,
      direccion: input.direccion,
      sucursalCentral: input.sucursalCentral,
      fechaCreacion: input.fechaCreacion,
      fechaActualizacion: input.fechaActualizacion
    }
  }
}
