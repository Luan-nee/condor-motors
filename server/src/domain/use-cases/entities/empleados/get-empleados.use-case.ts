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
import { ilike, or, type SQL, asc, desc, and, eq } from 'drizzle-orm'

interface GetEmpleadoArgs {
  queriesDto: QueriesDto
  order: SQL
  whereCondition: SQL | undefined
}

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
    dni: empleadosTable.dni
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

  private async getRelated({
    queriesDto,
    order,
    whereCondition,
    sucursalId
  }: GetEmpleadoArgs & { sucursalId: SucursalIdType }) {
    return await db
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
      .where(and(eq(sucursalesTable.id, sucursalId), whereCondition))
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))
  }

  private async getAny({ queriesDto, order, whereCondition }: GetEmpleadoArgs) {
    return await db
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

    const whereCondition =
      queriesDto.search.length > 0
        ? or(
            ilike(empleadosTable.dni, `%${queriesDto.search}%`),
            ilike(empleadosTable.nombre, `%${queriesDto.search}%`),
            ilike(empleadosTable.apellidos, `%${queriesDto.search}%`)
          )
        : undefined

    const args = {
      queriesDto,
      order,
      whereCondition
    }

    const empleados = hasPermissionAny
      ? await this.getAny(args)
      : await this.getRelated({ ...args, sucursalId })

    if (empleados.length < 1) {
      return []
    }

    return empleados
  }

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny, this.permissionRelated]
    )

    const hasPermissionAny = validPermissions.some(
      (permission) => permission.codigoPermiso === this.permissionAny
    )

    if (
      !hasPermissionAny &&
      !validPermissions.some(
        (permission) => permission.codigoPermiso === this.permissionRelated
      )
    ) {
      throw CustomError.forbidden()
    }

    const [permission] = validPermissions

    return { hasPermissionAny, sucursalId: permission.sucursalId }
  }

  async execute(queriesDto: QueriesDto) {
    const { hasPermissionAny, sucursalId } = await this.validatePermissions()

    const empleados = await this.getEmpleados(
      queriesDto,
      hasPermissionAny,
      sucursalId
    )

    return empleados
  }
}
