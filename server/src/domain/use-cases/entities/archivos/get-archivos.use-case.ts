import { permissionCodes } from '@/consts'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { archivosAppTable, cuentasEmpleadosTable } from '@/db/schema'
import { desc, eq } from 'drizzle-orm'

export class GetArchivos {
  private readonly permissionAny = permissionCodes.archivos.getAny
  private readonly selectFields = {
    id: archivosAppTable.id,
    nombre: archivosAppTable.nombre,
    filename: archivosAppTable.filename,
    tipo: archivosAppTable.tipo,
    size: archivosAppTable.size,
    metadata: archivosAppTable.metadata,
    version: archivosAppTable.version,
    fechaCreacion: archivosAppTable.fechaCreacion,
    user: {
      id: cuentasEmpleadosTable.id,
      nombre: cuentasEmpleadosTable.usuario
    }
  }

  constructor(private readonly permissionsList: Permission[]) {}

  private async getArchivos() {
    const files = await db
      .select(this.selectFields)
      .from(archivosAppTable)
      .leftJoin(
        cuentasEmpleadosTable,
        eq(archivosAppTable.userId, cuentasEmpleadosTable.id)
      )
      .orderBy(desc(archivosAppTable.fechaCreacion))

    return files
  }

  private validatePermissions() {
    if (
      !this.permissionsList.some((p) => p.codigoPermiso === this.permissionAny)
    ) {
      throw CustomError.forbidden()
    }
  }

  async execute() {
    this.validatePermissions()

    return await this.getArchivos()
  }
}
