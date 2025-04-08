import { db } from '@/db/connection'
import { Workbook } from 'exceljs'

import {
  coloresTable,
  detallesProductoTable,
  marcasTable,
  productosTable,
  sucursalesTable
} from '@/db/schema'
import { eq } from 'drizzle-orm'
import { CustomError } from '@/core/errors/custom.error'

interface ProductoPlano {
  id: number
  nombre: string
  descripcion: string | null
  descuento: number | null
  color: string
  marca: number
  detallesproducto: {
    stock: number | null
    liquidacion: boolean | null
    sucursal: string | null
  }
}

interface FilaReporte {
  id: number
  nombre: string
  descripcion: string | null
  descuento: number | null
  color: string
  marca: number
  [sucursalNombre: string]: string | number | null | undefined
  Total?: number
}

export class GetProductosReporte {
  private crearFilaProducto(row: ProductoPlano): FilaReporte {
    const { id, nombre, descripcion, descuento, color, marca } = row
    return {
      id,
      nombre,
      descripcion,
      descuento,
      color,
      marca
    }
  }

  private actualizarStockPorSucursal(
    fila: FilaReporte,
    detallesproducto: ProductoPlano['detallesproducto']
  ) {
    const { stock, sucursal } = detallesproducto
    if (sucursal != null) {
      const stockActual =
        typeof fila[sucursal] === 'number' ? fila[sucursal] : 0
      fila[sucursal] = stockActual + (stock ?? 0)
    }
  }

  private pivotarProductosPorSucursal(datos: ProductoPlano[]): FilaReporte[] {
    const reporteMap = new Map<number, FilaReporte>()

    for (const row of datos) {
      const { id: key, detallesproducto } = row

      if (!reporteMap.has(key)) {
        reporteMap.set(key, this.crearFilaProducto(row))
      }

      const fila = reporteMap.get(key)
      if (fila === undefined) continue

      this.actualizarStockPorSucursal(fila, detallesproducto)
    }

    for (const fila of reporteMap.values()) {
      const total = Object.entries(fila).reduce((acc, [key, value]) => {
        if (
          ![
            'id',
            'nombre',
            'descripcion',
            'descuento',
            'color',
            'marca',
            'Total'
          ].includes(key) &&
          typeof value === 'number'
        ) {
          return acc + value
        }
        return acc
      }, 0)
      fila.Total = total
    }

    return Array.from(reporteMap.values())
  }

  private async getProductos() {
    const datos = await db
      .select({
        id: productosTable.id,
        nombre: productosTable.nombre,
        descripcion: productosTable.descripcion,
        descuento: productosTable.porcentajeDescuento,
        color: coloresTable.nombre,
        marca: marcasTable.id,
        detallesproducto: {
          stock: detallesProductoTable.stock,
          liquidacion: detallesProductoTable.liquidacion,
          sucursal: sucursalesTable.nombre
        }
      })
      .from(productosTable)
      .innerJoin(coloresTable, eq(coloresTable.id, productosTable.colorId))
      .innerJoin(marcasTable, eq(marcasTable.id, productosTable.marcaId))
      .innerJoin(
        detallesProductoTable,
        eq(detallesProductoTable.productoId, productosTable.id)
      )
      .innerJoin(
        sucursalesTable,
        eq(sucursalesTable.id, detallesProductoTable.sucursalId)
      )
    if (datos.length <= 0) {
      return []
    }

    return this.pivotarProductosPorSucursal(datos)
  }
  private async createExcelFile() {
    const valores = await this.getProductos()
    if (valores.length === 0) {
      CustomError.serviceUnavailable('No existen productos por ahora')
    }
    const cabecera = Object.keys(valores[0])

    const workbook = new Workbook()
    const worksheet = workbook.addWorksheet('Datos')

    worksheet.columns = cabecera.map((key) => ({
      header: key.charAt(0).toUpperCase() + key.slice(1),
      key,
      width: 20,
      style: {
        font: { bold: true },
        color: {
          fill: {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: 'FFFFCC00' }
          }
        }
      }
    }))

    valores.forEach((row) => {
      worksheet.addRow(row)
    })

    await workbook.xlsx.writeFile('storage/private/reportes/archivo.xlsx')
    return { archivo: 'archivo.xlsx' }
  }
  async execute() {
    const resultado = await this.createExcelFile()
    return resultado
  }
}
