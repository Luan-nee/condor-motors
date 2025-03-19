import { db } from '@/db/connection'
import { notificacionesTable, sucursalesTable } from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import type { SucursalIdType } from '@/types/schemas'
import { asc, eq } from 'drizzle-orm'

export class GetNotificaciones {
  private readonly authpayload: AuthPayload
  private readonly selectFields = {
    id: notificacionesTable.id,
    titulo: notificacionesTable.titulo,
    descripcion: notificacionesTable.descripcion,
    nombre: sucursalesTable.nombre,
    fecha_creacion: notificacionesTable.fechaCreacion
  }

  constructor(authpayload: AuthPayload) {
    this.authpayload = authpayload
  }

  private async getNotificaciones(
    queriesDto: QueriesDto,
    sucursalID: SucursalIdType
  ) {
    const notificaciones = await db
      .select(this.selectFields)
      .from(notificacionesTable)
      .innerJoin(
        sucursalesTable,
        eq(sucursalesTable.id, notificacionesTable.sucursalId)
      )
      .where(eq(notificacionesTable.sucursalId, sucursalID))
      .orderBy(asc(notificacionesTable.fechaCreacion))

    return notificaciones
  }
}
