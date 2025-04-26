import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  cuentasEmpleadosTable,
  empleadosTable,
  rolesTable,
  sucursalesTable
} from '@/db/schema'
import { eq } from 'drizzle-orm'

export class TestSession {
  private readonly selectFields = {
    id: cuentasEmpleadosTable.id,
    usuario: cuentasEmpleadosTable.usuario,
    rolCuentaEmpleadoId: cuentasEmpleadosTable.rolId,
    rolCuentaEmpleadoCodigo: rolesTable.codigo,
    empleadoId: cuentasEmpleadosTable.empleadoId,
    empleado: {
      activo: empleadosTable.activo,
      nombres: empleadosTable.nombre,
      apellidos: empleadosTable.apellidos,
      pathFoto: empleadosTable.pathFoto
    },
    fechaCreacion: cuentasEmpleadosTable.fechaCreacion,
    fechaActualizacion: cuentasEmpleadosTable.fechaActualizacion,
    sucursal: sucursalesTable.nombre,
    sucursalId: sucursalesTable.id
  }

  constructor(private readonly authPayload: AuthPayload) {}

  private async testSession() {
    const users = await db
      .select(this.selectFields)
      .from(cuentasEmpleadosTable)
      .innerJoin(rolesTable, eq(rolesTable.id, cuentasEmpleadosTable.rolId))
      .innerJoin(
        empleadosTable,
        eq(empleadosTable.id, cuentasEmpleadosTable.empleadoId)
      )
      .innerJoin(
        sucursalesTable,
        eq(sucursalesTable.id, empleadosTable.sucursalId)
      )
      .where(eq(cuentasEmpleadosTable.id, this.authPayload.id))

    if (users.length < 1) {
      throw CustomError.unauthorized('User does not exists')
    }

    const [user] = users

    if (!user.empleado.activo) {
      throw CustomError.badRequest(
        'Su cuenta de usuario se encuentra desactivada, contacte al administrador para que este habilite su cuenta'
      )
    }

    return user
  }

  async execute() {
    const user = await this.testSession()

    return user
  }
}
