import type { EmpleadoEntity } from '@/types/schemas'

export class EmpleadoEntityMapper {
  static fromObject(input: EmpleadoEntity) {
    const parsedId = String(input.id)
    const parsedSucursalId = String(input.sucursalId)

    const parsedSueldo =
      typeof input.sueldo === 'string' ? parseFloat(input.sueldo) : input.sueldo

    return {
      id: parsedId,
      nombre: input.nombre,
      apellidos: input.apellidos,
      ubicacionFoto: input.ubicacionFoto,
      edad: input.edad,
      dni: input.dni,
      horaInicioJornada: input.horaInicioJornada,
      horaFinJornada: input.horaFinJornada,
      fechaContratacion: input.fechaContratacion,
      sueldo: parsedSueldo,
      sucursalId: parsedSucursalId,
      fechaCreacion: input.fechaCreacion,
      fechaActualizacion: input.fechaActualizacion
    }
  }
}
