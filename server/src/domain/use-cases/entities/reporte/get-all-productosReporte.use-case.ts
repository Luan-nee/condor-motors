import { db } from '@/db/connection'
import {
  coloresTable,
  detallesProductoTable,
  marcasTable,
  productosTable,
  sucursalesTable
} from '@/db/schema'
import { eq } from 'drizzle-orm'

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

    const reporteFinal: FilaReporte[] = []

    return reporteFinal
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
      .leftJoin(
        detallesProductoTable,
        eq(detallesProductoTable.productoId, productosTable.id)
      )
      .leftJoin(
        sucursalesTable,
        eq(sucursalesTable.id, detallesProductoTable.sucursalId)
      )
    return this.pivotarProductosPorSucursal(datos)
  }

  async execute() {
    const resultado = await this.getProductos()
    return resultado
  }
}
