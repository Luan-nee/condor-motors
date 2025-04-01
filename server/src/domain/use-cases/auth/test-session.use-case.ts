import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { cuentasEmpleadosTable, rolesTable } from '@/db/schema'
import { eq } from 'drizzle-orm'

export class TestSession {
  private readonly selectFields = {
    id: cuentasEmpleadosTable.id,
    usuario: cuentasEmpleadosTable.usuario,
    rol: {
      codigo: rolesTable.codigo,
      nombre: rolesTable.nombre
    }
  }

  constructor(private readonly authPayload: AuthPayload) {}

  private async testSession() {
    const users = await db
      .select(this.selectFields)
      .from(cuentasEmpleadosTable)
      .innerJoin(rolesTable, eq(cuentasEmpleadosTable.rolId, rolesTable.id))
      .where(eq(cuentasEmpleadosTable.id, this.authPayload.id))

    if (users.length < 1) {
      throw CustomError.unauthorized('User does not exists')
    }

    const [user] = users

    return user
  }

  async execute() {
    const user = await this.testSession()

    return user
  }
}
