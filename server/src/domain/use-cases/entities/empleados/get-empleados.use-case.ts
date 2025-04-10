import { orderValues, permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  cuentasEmpleadosTable,
  empleadosTable,
  rolesTable,
  sucursalesTable
} from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import type { SucursalIdType } from '@/types/schemas'
import { ilike, or, asc, desc, and, eq, count } from 'drizzle-orm'

export class GetEmpleados {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.empleados.getAny
  private readonly permissionRelated = permissionCodes.empleados.getRelated
  private readonly selectFields = {
    id: empleadosTable.id,
    nombre: empleadosTable.nombre,
    apellidos: empleadosTable.apellidos,
    activo: empleadosTable.activo,
    dni: empleadosTable.dni,
    pathFoto: empleadosTable.pathFoto,
    celular: empleadosTable.celular,
    horaInicioJornada: empleadosTable.horaInicioJornada,
    horaFinJornada: empleadosTable.horaFinJornada,
    fechaContratacion: empleadosTable.fechaContratacion,
    sueldo: empleadosTable.sueldo,
    sucursal: {
      id: sucursalesTable.id,
      nombre: sucursalesTable.nombre,
      sucursalCentral: sucursalesTable.sucursalCentral
    },
    cuentaEmpleado: {
      id: cuentasEmpleadosTable.id,
      usuario: cuentasEmpleadosTable.usuario
    },
    rol: {
      codigo: rolesTable.codigo,
      nombre: rolesTable.nombre
    }
  }

  private readonly validSortBy = {
    fechaCreacion: empleadosTable.fechaCreacion,
    nombre: empleadosTable.nombre,
    apellidos: empleadosTable.apellidos,
    dni: empleadosTable.dni,
    sueldo: empleadosTable.sueldo,
    fechaContratacion: empleadosTable.fechaContratacion,
    rol: rolesTable.nombre
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

  private async getEmpleados(
    queriesDto: QueriesDto,
    hasPermissionAny: boolean,
    sucursalId: SucursalIdType
  ) {
    const sortByColumn = this.getSortByColumn(queriesDto.sort_by)
    const order =
      queriesDto.order === orderValues.asc
        ? asc(sortByColumn)
        : desc(sortByColumn)

    const searchCondition =
      queriesDto.search.length > 0
        ? or(
            ilike(empleadosTable.dni, `%${queriesDto.search}%`),
            ilike(empleadosTable.nombre, `%${queriesDto.search}%`),
            ilike(empleadosTable.apellidos, `%${queriesDto.search}%`)
          )
        : undefined

    const whereCondition = and(
      hasPermissionAny ? undefined : eq(sucursalesTable.id, sucursalId),
      searchCondition
    )

    const empleados = await db
      .select(this.selectFields)
      .from(empleadosTable)
      .innerJoin(
        sucursalesTable,
        eq(empleadosTable.sucursalId, sucursalesTable.id)
      )
      .leftJoin(
        cuentasEmpleadosTable,
        eq(empleadosTable.id, cuentasEmpleadosTable.empleadoId)
      )
      .leftJoin(rolesTable, eq(cuentasEmpleadosTable.rolId, rolesTable.id))
      .where(whereCondition)
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))

    if (empleados.length < 1) {
      return []
    }

    return empleados
  }

  private getMetadata() {
    return {
      sortByOptions: Object.keys(this.validSortBy)
    }
  }

  private async getPagination(
    queriesDto: QueriesDto,
    hasPermissionAny: boolean,
    sucursalId: SucursalIdType
  ) {
    const searchCondition =
      queriesDto.search.length > 0
        ? or(
            ilike(empleadosTable.dni, `%${queriesDto.search}%`),
            ilike(empleadosTable.nombre, `%${queriesDto.search}%`),
            ilike(empleadosTable.apellidos, `%${queriesDto.search}%`)
          )
        : undefined

    const whereCondition = and(
      hasPermissionAny ? undefined : eq(sucursalesTable.id, sucursalId),
      searchCondition
    )

    const results = await db
      .select({ count: count(empleadosTable.id) })
      .from(empleadosTable)
      .where(whereCondition)

    const [totalItems] = results

    const totalPages = Math.ceil(totalItems.count / queriesDto.page_size)
    const hasNext = queriesDto.page < totalPages && queriesDto.page >= 1
    const hasPrev = queriesDto.page > 1 && queriesDto.page <= totalPages

    return {
      totalItems: totalItems.count,
      totalPages,
      currentPage: queriesDto.page,
      hasNext,
      hasPrev
    }
  }

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny, this.permissionRelated]
    )

    let hasPermissionAny = false
    let hasPermissionRelated = false

    for (const permission of validPermissions) {
      if (permission.codigoPermiso === this.permissionAny) {
        hasPermissionAny = true
      }
      if (permission.codigoPermiso === this.permissionRelated) {
        hasPermissionRelated = true
      }

      if (hasPermissionAny || hasPermissionRelated) {
        return { hasPermissionAny, sucursalId: permission.sucursalId }
      }
    }

    throw CustomError.forbidden()
  }

  async execute(queriesDto: QueriesDto) {
    const { hasPermissionAny, sucursalId } = await this.validatePermissions()

    const metadata = this.getMetadata()
    const pagination = await this.getPagination(
      queriesDto,
      hasPermissionAny,
      sucursalId
    )

    const isValidPage =
      (pagination.currentPage <= pagination.totalPages ||
        pagination.currentPage >= 1) &&
      pagination.totalItems > 0

    const results = isValidPage
      ? await this.getEmpleados(queriesDto, hasPermissionAny, sucursalId)
      : []

    return {
      results,
      pagination,
      metadata
    }
  }
}
