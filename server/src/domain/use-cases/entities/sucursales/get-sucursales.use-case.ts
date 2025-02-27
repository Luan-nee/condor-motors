import { orderValues, permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  cuentasEmpleadosTable,
  empleadosTable,
  sucursalesTable
} from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import { SucursalEntityMapper } from '@/domain/mappers/sucursal-entity.mapper'
import { and, asc, desc, eq, ilike, or, type SQL } from 'drizzle-orm'

export class GetSucursales {
  private readonly authPayload: AuthPayload
  private readonly permissionGetAny = permissionCodes.sucursales.getAny
  private readonly permissionGetRelated = permissionCodes.sucursales.getRelated
  private readonly selectFields = {
    id: sucursalesTable.id,
    nombre: sucursalesTable.nombre,
    direccion: sucursalesTable.direccion,
    sucursalCentral: sucursalesTable.sucursalCentral,
    fechaCreacion: sucursalesTable.fechaCreacion,
    fechaActualizacion: sucursalesTable.fechaActualizacion
  }

  private readonly validSortBy = {
    fechaCreacion: sucursalesTable.fechaCreacion,
    nombre: sucursalesTable.nombre,
    direccion: sucursalesTable.direccion,
    sucursalCentral: sucursalesTable.sucursalCentral
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

  private async getRelatedSucursales(
    queriesDto: QueriesDto,
    order: SQL,
    whereCondition: SQL | undefined
  ) {
    return await db
      .select(this.selectFields)
      .from(sucursalesTable)
      .innerJoin(
        empleadosTable,
        eq(empleadosTable.sucursalId, sucursalesTable.id)
      )
      .innerJoin(
        cuentasEmpleadosTable,
        eq(cuentasEmpleadosTable.empleadoId, empleadosTable.id)
      )
      .where(
        and(whereCondition, eq(cuentasEmpleadosTable.id, this.authPayload.id))
      )
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))
  }

  private async getAnySucursales(
    queriesDto: QueriesDto,
    order: SQL,
    whereCondition: SQL | undefined
  ) {
    return await db
      .select(this.selectFields)
      .from(sucursalesTable)
      .where(whereCondition)
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))
  }

  private async getSucursales(
    queriesDto: QueriesDto,
    hasPermissionGetAny: boolean
  ) {
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

    const sucursales = hasPermissionGetAny
      ? await this.getAnySucursales(queriesDto, order, whereCondition)
      : await this.getRelatedSucursales(queriesDto, order, whereCondition)

    if (sucursales.length <= 0) {
      return []
    }

    return sucursales
  }

  async execute(queriesDto: QueriesDto) {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionGetAny, this.permissionGetRelated]
    )

    if (
      !validPermissions.some(
        (permission) => permission.codigoPermiso === this.permissionGetAny
      ) &&
      !validPermissions.some(
        (permission) => permission.codigoPermiso === this.permissionGetRelated
      )
    ) {
      throw CustomError.forbidden(
        'No tienes los suficientes permisos para realizar esta acción'
      )
    }

    const hasPermissionGetAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionGetAny
    )

    const sucursales = await this.getSucursales(queriesDto, hasPermissionGetAny)

    const mappedSucursales = sucursales.map((sucursal) =>
      SucursalEntityMapper.sucursalEntityFromObject(sucursal)
    )

    return mappedSucursales
  }
}
