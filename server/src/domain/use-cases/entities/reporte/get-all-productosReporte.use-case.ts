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
  color: string
  marca: number | string
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
  color: string
  marca: number | string
  [sucursalNombre: string]: string | number | null | undefined
  Total?: number
}

export class GetProductosReporte {
  private crearFilaProducto(row: ProductoPlano): FilaReporte {
    const { id, nombre, descripcion, color, marca } = row
    return {
      id,
      nombre,
      descripcion,
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
          !['id', 'nombre', 'descripcion', 'color', 'marca', 'Total'].includes(
            key
          ) &&
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
        color: coloresTable.nombre,
        marca: marcasTable.nombre,
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

  private async getProductosSucursales(idSucursal: number) {
    const datos = await db
      .select({
        nombre: productosTable.nombre,
        precioVenta: detallesProductoTable.precioVenta,
        stock: detallesProductoTable.stock
      })
      .from(detallesProductoTable)
      .innerJoin(
        productosTable,
        eq(productosTable.id, detallesProductoTable.productoId)
      )
      .where(eq(detallesProductoTable.sucursalId, idSucursal))
    return datos
  }

  private async getSucursales() {
    const datos = await db
      .select({
        id: sucursalesTable.id,
        nombre: sucursalesTable.nombre
      })
      .from(sucursalesTable)
    return datos
  }

  private crearHoja(
    tablaPrincipal: Workbook,
    titulo: string,
    datos: any[]
  ): void {
    if (datos.length === 0) return
    const hoja = tablaPrincipal.addWorksheet(titulo)
    const cabecera = Object.keys(datos[0])
    hoja.columns = cabecera.map((key) => ({
      header: key.charAt(0).toUpperCase() + key.slice(1),
      key,
      width: 20 + key.length
    }))
    hoja.addRow([])
    datos.forEach((row: any) => {
      hoja.addRow(row)
    })

    const filaCabecera = hoja.getRow(1)
    filaCabecera.eachCell((cell) => {
      cell.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FFFFCC00' }
      }
      cell.font = { bold: true }
    })
    filaCabecera.commit()
  }

  private async createExcelFile() {
    const valores = await this.getProductos()
    if (valores.length === 0) {
      CustomError.serviceUnavailable('No existen productos por ahora')
    }

    const workbook = new Workbook()

    this.crearHoja(workbook, 'Principal', valores)
    const sucursales = await this.getSucursales()
    if (sucursales.length > 0) {
      for (const valor of sucursales) {
        const datosAux = await this.getProductosSucursales(valor.id)
        if (datosAux.length > 0) {
          this.crearHoja(workbook, valor.nombre, datosAux)
        }
      }
    }

    await workbook.xlsx.writeFile('storage/private/reportes/archivo.xlsx')
    return { archivo: 'archivo.xlsx' }
  }
  async execute() {
    const resultado = await this.createExcelFile()
    return resultado
  }
}
