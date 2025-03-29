import { orderValues, permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  clientesTable,
  empleadosTable,
  proformasVentaTable,
  sucursalesTable
} from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, asc, desc, eq, ilike, or } from 'drizzle-orm'

export class GetProformasVenta {
  private readonly authPayload: AuthPayload
  private readonly permissionGetAny = permissionCodes.productos.getAny
  private readonly permissionGetRelated = permissionCodes.productos.getRelated
  private readonly selectFields = {
    id: proformasVentaTable.id,
    nombre: proformasVentaTable.nombre,
    total: proformasVentaTable.total,
    cliente: {
      id: clientesTable.id,
      nombre: clientesTable.denominacion,
      numeroDocumento: clientesTable.numeroDocumento
    },
    empleado: {
      id: empleadosTable.id,
      nombre: empleadosTable.nombre
    },
    sucursal: {
      id: sucursalesTable.id,
      nombre: sucursalesTable.nombre
    },
    detalles: proformasVentaTable.detalles,
    fechaCreacion: proformasVentaTable.fechaCreacion,
    fechaActualizacion: proformasVentaTable.fechaActualizacion
  }

  private readonly validSortBy = {
    fechaCreacion: proformasVentaTable.fechaCreacion,
    fechaActualizacion: proformasVentaTable.fechaCreacion
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

  private async getProformasVenta(
    queriesDto: QueriesDto,
    sucursalId: SucursalIdType
  ) {
    const sortByColumn = this.getSortByColumn(queriesDto.sort_by)

    const order =
      queriesDto.order === orderValues.asc
        ? asc(sortByColumn)
        : desc(sortByColumn)

    const whereCondition =
      queriesDto.search.length > 0
        ? or(ilike(proformasVentaTable.nombre, `%${queriesDto.search}%`))
        : undefined

    const proformasVenta = await db
      .select(this.selectFields)
      .from(proformasVentaTable)
      .innerJoin(
        empleadosTable,
        eq(proformasVentaTable.empleadoId, empleadosTable.id)
      )
      .innerJoin(
        sucursalesTable,
        eq(proformasVentaTable.sucursalId, sucursalesTable.id)
      )
      .leftJoin(
        clientesTable,
        eq(proformasVentaTable.clienteId, clientesTable.id)
      )
      .where(
        and(eq(proformasVentaTable.sucursalId, sucursalId), whereCondition)
      )
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))

    return proformasVenta
  }

  private async validatePermissions(sucursalId: SucursalIdType) {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionGetAny, this.permissionGetRelated]
    )

    const hasPermissionGetAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionGetAny
    )

    if (
      !hasPermissionGetAny &&
      !validPermissions.some(
        (permission) => permission.codigoPermiso === this.permissionGetRelated
      )
    ) {
      throw CustomError.forbidden()
    }

    const isSameSucursal = validPermissions.some(
      (permission) => permission.sucursalId === sucursalId
    )

    if (!hasPermissionGetAny && !isSameSucursal) {
      throw CustomError.forbidden()
    }
  }

  async execute(queriesDto: QueriesDto, sucursalId: SucursalIdType) {
    await this.validatePermissions(sucursalId)

    const proformasVenta = await this.getProformasVenta(queriesDto, sucursalId)

    return proformasVenta
  }
}
