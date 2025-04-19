import { orderValues, permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  docsFacturacionTable,
  empleadosTable,
  estadosDocFacturacionTable,
  sucursalesTable,
  tiposDocFacturacionTable,
  totalesVentaTable,
  ventasTable
} from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, asc, count, desc, eq, ilike, or } from 'drizzle-orm'

export class GetVentas {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.ventas.getAny
  private readonly permissionRelated = permissionCodes.ventas.getRelated
  private readonly selectFields = {
    id: ventasTable.id,
    declarada: ventasTable.declarada,
    anulada: ventasTable.anulada,
    cancelada: ventasTable.cancelada,
    serieDocumento: ventasTable.serieDocumento,
    numeroDocumento: ventasTable.numeroDocumento,
    tipoDocumento: tiposDocFacturacionTable.nombre,
    fechaEmision: ventasTable.fechaEmision,
    horaEmision: ventasTable.horaEmision,
    empleado: {
      id: empleadosTable.id,
      nombre: empleadosTable.nombre,
      apellidos: empleadosTable.apellidos
    },
    sucursal: {
      id: sucursalesTable.id,
      nombre: sucursalesTable.nombre
    },
    totalesVenta: {
      totalGravadas: totalesVentaTable.totalGravadas,
      totalExoneradas: totalesVentaTable.totalExoneradas,
      totalGratuitas: totalesVentaTable.totalGratuitas,
      totalTax: totalesVentaTable.totalTax,
      totalVenta: totalesVentaTable.totalVenta
    },
    estado: {
      codigo: estadosDocFacturacionTable.codigo,
      nombre: estadosDocFacturacionTable.nombre
    },
    documentoFacturacion: {
      id: docsFacturacionTable.id,
      codigoEstadoSunat: docsFacturacionTable.estadoRawId,
      linkPdf: docsFacturacionTable.linkPdf
    }
  }

  private readonly validSortBy = {
    declarada: ventasTable.declarada,
    anulada: ventasTable.anulada,
    estadoDocFacturacion: estadosDocFacturacionTable.nombre,
    totalVenta: totalesVentaTable.totalVenta,
    documentoFacturacion: docsFacturacionTable.id,
    serieDocumento: ventasTable.serieDocumento,
    numeroDocumento: ventasTable.numeroDocumento,
    nombreEmpleado: empleadosTable.nombre,
    // denominacionCliente: clientesTable.denominacion,
    tipoDocumentoCliente: tiposDocFacturacionTable.nombre,
    fechaEmision: ventasTable.fechaEmision,
    fechaCreacion: ventasTable.fechaCreacion
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

  private async getVentas(queriesDto: QueriesDto, sucursalId: SucursalIdType) {
    const sortByColumn = this.getSortByColumn(queriesDto.sort_by)

    const order =
      queriesDto.order === orderValues.asc
        ? asc(sortByColumn)
        : desc(sortByColumn)

    const searchCondition =
      queriesDto.search.length > 0
        ? or(
            // ilike(clientesTable.denominacion, `%${queriesDto.search}%`),
            // ilike(clientesTable.numeroDocumento, `%${queriesDto.search}%`),
            ilike(ventasTable.serieDocumento, `%${queriesDto.search}%`),
            ilike(empleadosTable.nombre, `%${queriesDto.search}%`),
            ilike(empleadosTable.dni, `%${queriesDto.search}%`)
          )
        : undefined

    const whereCondition = searchCondition

    const ventas = await db
      .select(this.selectFields)
      .from(ventasTable)
      .innerJoin(
        totalesVentaTable,
        eq(ventasTable.id, totalesVentaTable.ventaId)
      )
      .innerJoin(
        tiposDocFacturacionTable,
        eq(ventasTable.tipoDocumentoId, tiposDocFacturacionTable.id)
      )
      .innerJoin(empleadosTable, eq(ventasTable.empleadoId, empleadosTable.id))
      .innerJoin(
        sucursalesTable,
        eq(ventasTable.sucursalId, sucursalesTable.id)
      )
      .leftJoin(
        docsFacturacionTable,
        eq(ventasTable.id, docsFacturacionTable.ventaId)
      )
      .leftJoin(
        estadosDocFacturacionTable,
        eq(docsFacturacionTable.estadoId, estadosDocFacturacionTable.id)
      )
      .where(and(eq(ventasTable.sucursalId, sucursalId), whereCondition))
      .orderBy(order)
      .limit(queriesDto.page_size)
      .offset(queriesDto.page_size * (queriesDto.page - 1))

    const mappedVentas = ventas.map((venta) => {
      if (venta.documentoFacturacion?.linkPdf != null) {
        const {
          documentoFacturacion: { linkPdf }
        } = venta

        const { linkPdfA4, linkPdfTicket } = this.getPdfUrls(linkPdf)

        return {
          ...venta,
          documentoFacturacion: {
            ...venta.documentoFacturacion,
            linkPdfA4,
            linkPdfTicket
          }
        }
      }

      return venta
    })

    return mappedVentas
  }

  private getPdfUrls(url: string) {
    try {
      const urlObj = new URL(url)
      const baseUrl = `${urlObj.origin}${urlObj.pathname}`

      const urlObjPdf = new URL(baseUrl)
      urlObjPdf.searchParams.set('type', 'a4')
      const linkPdfA4 = urlObjPdf.toString()

      const urlObjTicket = new URL(baseUrl)
      urlObjTicket.searchParams.set('type', 'ticket')
      const linkPdfTicket = urlObjTicket.toString()

      return {
        linkPdfA4,
        linkPdfTicket
      }
    } catch {
      return {
        linkPdfA4: null,
        linkPdfTicket: null
      }
    }
  }

  private getMetadata() {
    return {
      sortByOptions: Object.keys(this.validSortBy)
    }
  }

  private async getPagination(
    queriesDto: QueriesDto,
    sucursalId: SucursalIdType
  ) {
    const searchCondition =
      queriesDto.search.length > 0
        ? or(
            // ilike(clientesTable.denominacion, `%${queriesDto.search}%`),
            // ilike(clientesTable.numeroDocumento, `%${queriesDto.search}%`),
            ilike(ventasTable.serieDocumento, `%${queriesDto.search}%`),
            ilike(empleadosTable.nombre, `%${queriesDto.search}%`),
            ilike(empleadosTable.dni, `%${queriesDto.search}%`)
          )
        : undefined

    const whereCondition = searchCondition

    const results = await db
      .select({ count: count(ventasTable.id) })
      .from(ventasTable)
      .innerJoin(
        totalesVentaTable,
        eq(ventasTable.id, totalesVentaTable.ventaId)
      )
      .innerJoin(
        tiposDocFacturacionTable,
        eq(ventasTable.tipoDocumentoId, tiposDocFacturacionTable.id)
      )
      .innerJoin(empleadosTable, eq(ventasTable.empleadoId, empleadosTable.id))
      .innerJoin(
        sucursalesTable,
        eq(ventasTable.sucursalId, sucursalesTable.id)
      )
      .leftJoin(
        docsFacturacionTable,
        eq(ventasTable.id, docsFacturacionTable.ventaId)
      )
      .leftJoin(
        estadosDocFacturacionTable,
        eq(docsFacturacionTable.estadoId, estadosDocFacturacionTable.id)
      )
      .where(and(eq(ventasTable.sucursalId, sucursalId), whereCondition))

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

  private async validatePermissions(sucursalId: SucursalIdType) {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny, this.permissionRelated]
    )

    let hasPermissionAny = false
    let hasPermissionRelated = false
    let isSameSucursal = false

    for (const permission of validPermissions) {
      if (permission.codigoPermiso === this.permissionAny) {
        hasPermissionAny = true
      }
      if (permission.codigoPermiso === this.permissionRelated) {
        hasPermissionRelated = true
      }
      if (permission.sucursalId === sucursalId) {
        isSameSucursal = true
      }

      if (hasPermissionAny || (hasPermissionRelated && isSameSucursal)) {
        return
      }
    }

    throw CustomError.forbidden()
  }

  async execute(queriesDto: QueriesDto, sucursalId: SucursalIdType) {
    await this.validatePermissions(sucursalId)

    const metadata = this.getMetadata()
    const pagination = await this.getPagination(queriesDto, sucursalId)

    const isValidPage =
      (pagination.currentPage <= pagination.totalPages ||
        pagination.currentPage >= 1) &&
      pagination.totalItems > 0

    const results = isValidPage
      ? await this.getVentas(queriesDto, sucursalId)
      : []

    return {
      results,
      pagination,
      metadata
    }
  }
}
