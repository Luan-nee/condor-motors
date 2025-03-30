import { orderValues, permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { empleadosTable, sucursalesTable } from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { asc, count, desc, eq, ilike, or } from 'drizzle-orm'

export class GetSucursales {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.sucursales.getAny
  private readonly selectFields = {
    id: sucursalesTable.id,
    nombre: sucursalesTable.nombre,
    direccion: sucursalesTable.direccion,
    sucursalCentral: sucursalesTable.sucursalCentral,
    serieFactura: sucursalesTable.serieFactura,
    numeroFacturaInicial: sucursalesTable.numeroFacturaInicial,
    serieBoleta: sucursalesTable.serieBoleta,
    numeroBoletaInicial: sucursalesTable.numeroBoletaInicial,
    codigoEstablecimiento: sucursalesTable.codigoEstablecimiento,
    tieneNotificaciones: sucursalesTable.tieneNotificaciones,
    fechaCreacion: sucursalesTable.fechaCreacion,
    fechaActualizacion: sucursalesTable.fechaActualizacion,
    totalEmpleados: count(empleadosTable.id)
  }

  private readonly validSortBy = {
    fechaCreacion: sucursalesTable.fechaCreacion,
    nombre: sucursalesTable.nombre,
    direccion: sucursalesTable.direccion,
    sucursalCentral: sucursalesTable.sucursalCentral,
    serieFacturaSucursal: sucursalesTable.serieFactura,
    serieBoletaSucursal: sucursalesTable.serieBoleta,
    codigoEstablecimiento: sucursalesTable.codigoEstablecimiento
  } as const

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private isValidSortBy(
    sortBy: string
  ): sortBy is keyof typeof this.validSortBy {
    return Object.keys(this.validSortBy).includes(sortBy)
  }

  private getSortByColumn(sortBy: string) {
    if (
      Object.keys(this.validSortBy).includes(sortBy) &&
      this.isValidSortBy(sortBy)
    ) {
      return this.validSortBy[sortBy]
    }

    return this.validSortBy.fechaCreacion
  }

  private async getSucursales(queriesDto: QueriesDto) {
    const sortByColumn = this.getSortByColumn(queriesDto.sort_by)

    const order =
      queriesDto.order === orderValues.asc
        ? asc(sortByColumn)
        : desc(sortByColumn)

    const whereCondition =
      queriesDto.search.length > 0
        ? or(
            ilike(sucursalesTable.nombre, `%${queriesDto.search}%`),
            ilike(sucursalesTable.direccion, `%${queriesDto.search}%`)
          )
        : undefined

    const sucursales = await db
      .select(this.selectFields)
      .from(sucursalesTable)
      .leftJoin(
        empleadosTable,
        eq(sucursalesTable.id, empleadosTable.sucursalId)
      )
      .where(whereCondition)
      .groupBy(sucursalesTable.id)
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))

    return sucursales
  }

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny]
    )

    let hasPermissionAny = false

    for (const permission of validPermissions) {
      if (permission.codigoPermiso === this.permissionAny) {
        hasPermissionAny = true
      }

      if (hasPermissionAny) {
        return
      }
    }

    throw CustomError.forbidden()
  }

  async execute(queriesDto: QueriesDto) {
    await this.validatePermissions()

    const sucursales = await this.getSucursales(queriesDto)

    return sucursales
  }
}
