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
import { desc, eq } from 'drizzle-orm'

export class GetUltimasVentas {
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
    sucursal: {
      id: sucursalesTable.id,
      sucursalCentral: sucursalesTable.sucursalCentral,
      nombre: sucursalesTable.nombre
    },
    totalesVenta: {
      totalVenta: totalesVentaTable.totalVenta
    },
    estado: {
      codigo: estadosDocFacturacionTable.codigo,
      nombre: estadosDocFacturacionTable.nombre
    }
    // documentoFacturacion: {
    //   id: docsFacturacionTable.id,
    //   codigoEstadoSunat: docsFacturacionTable.estadoRawId,
    //   linkPdf: docsFacturacionTable.linkPdf
    // }
  }

  private async getVentas() {
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
      .orderBy(desc(ventasTable.fechaCreacion))
      .limit(5)

    // const mappedVentas = ventas.map((venta) => {
    //   if (venta.documentoFacturacion?.linkPdf != null) {
    //     const {
    //       documentoFacturacion: { linkPdf }
    //     } = venta

    //     const { linkPdfA4, linkPdfTicket } = this.getPdfUrls(linkPdf)

    //     return {
    //       ...venta,
    //       documentoFacturacion: {
    //         ...venta.documentoFacturacion,
    //         linkPdfA4,
    //         linkPdfTicket
    //       }
    //     }
    //   }

    //   return venta
    // })

    return ventas
  }

  async execute() {
    const ultimasVentas = await this.getVentas()

    return ultimasVentas
  }
}
