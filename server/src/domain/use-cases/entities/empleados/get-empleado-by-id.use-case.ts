// import { permissionCodes } from "@/consts";
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { empleadosTable, sucursalesTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { and, eq } from 'drizzle-orm'

export class GetEmpleadoById {
  private readonly authPayload: AuthPayload
  // private readonly permissionGetAny = permissionCodes.empleados.getAny;
  // private readonly permissionGetRelated = permissionCodes.empleados
  private readonly selectFields = {
    id: empleadosTable.id,
    nombre: empleadosTable.nombre,
    apellidos: empleadosTable.apellidos,
    ubicacionFoto: empleadosTable.ubicacionFoto,
    edad: empleadosTable.edad,
    dni: empleadosTable.dni,
    horaInicioJornada: empleadosTable.horaInicioJornada,
    horaFinJornada: empleadosTable.horaFinJornada,
    fechaContratacion: empleadosTable.fechaContratacion,
    sueldo: empleadosTable.sueldo,
    sucursalId: empleadosTable.sucursalId
  }

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }
  private async getRelatedEmpleado(numericIdDto: NumericIdDto) {
    return await db
      .select(this.selectFields)
      .from(empleadosTable)
      .innerJoin(
        sucursalesTable,
        eq(sucursalesTable.id, empleadosTable.sucursalId)
      )
      .where(and(eq(empleadosTable.id, numericIdDto.id)))
  }

  async execute(numericIdDto: NumericIdDto) {
    const empleado = await this.getRelatedEmpleado(numericIdDto)
    // const
    if (empleado.length <= 0) {
      throw CustomError.forbidden(
        `El usuario con el ID : ${numericIdDto.id} no existe `
      )
    }
    return empleado
  }
}
