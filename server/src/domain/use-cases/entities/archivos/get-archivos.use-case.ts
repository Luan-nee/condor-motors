import { permissionCodes } from '@/consts'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { archivosAppTable, cuentasEmpleadosTable } from '@/db/schema'
import { desc, eq } from 'drizzle-orm'

export class GetArchivos {
  private readonly permissionAny = permissionCodes.archivos.getAny
  private readonly permissionVisible = permissionCodes.archivos.getVisible
  private readonly selectFields = {
    id: archivosAppTable.id,
    nombre: archivosAppTable.nombre,
    filename: archivosAppTable.filename,
    tipo: archivosAppTable.tipo,
    size: archivosAppTable.size,
    metadata: archivosAppTable.metadata,
    visible: archivosAppTable.visible,
    fechaCreacion: archivosAppTable.fechaCreacion,
    user: {
      id: cuentasEmpleadosTable.id,
      nombre: cuentasEmpleadosTable.usuario
    }
  }

  constructor(
    // private readonly authPayload: AuthPayload,
    private readonly permissionsList: Permission[]
  ) {}

  private async getArchivos(hasPermissionAny: boolean) {
    const whereCondition = hasPermissionAny
      ? undefined
      : eq(archivosAppTable.visible, true)

    const files = await db
      .select(this.selectFields)
      .from(archivosAppTable)
      .leftJoin(
        cuentasEmpleadosTable,
        eq(archivosAppTable.userId, cuentasEmpleadosTable.id)
      )
      .where(whereCondition)
      .orderBy(desc(archivosAppTable.fechaCreacion))

    return files
  }

  private validatePermissions() {
    let hasPermissionAny = false
    let hasPermissionVisible = false

    for (const permission of this.permissionsList) {
      if (permission.codigoPermiso === this.permissionAny) {
        hasPermissionAny = true
      }

      if (permission.codigoPermiso === this.permissionVisible) {
        hasPermissionVisible = true
      }

      if (hasPermissionAny || hasPermissionVisible) {
        return { hasPermissionAny }
      }
    }

    throw CustomError.forbidden()
  }

  async execute() {
    const { hasPermissionAny } = this.validatePermissions()

    return await this.getArchivos(hasPermissionAny)
  }
}
