import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  categoriasTable,
  coloresTable,
  detallesProductoTable,
  marcasTable,
  productosTable,
  sucursalesTable
} from '@/db/schema'
import type { SucursalIdType } from '@/types/schemas'
import { eq } from 'drizzle-orm'

export class GetByIdData {
  private readonly selectFields = {
    nombre: productosTable.nombre,
    descripcion: productosTable.descripcion,
    maxDiasSinReabastecer: productosTable.maxDiasSinReabastecer,
    stockMinimo: productosTable.stockMinimo,
    cantidadMinimaDescuento: productosTable.cantidadMinimaDescuento,
    cantidadGratisDescuento: productosTable.cantidadGratisDescuento,
    porcentajeDescuento: productosTable.porcentajeDescuento,
    color: coloresTable.nombre,
    categoria: categoriasTable.id,
    marca: marcasTable.nombre
  }

  private readonly fieldsSucursales = {
    sucursal: {
      id: sucursalesTable.id,
      nombre: sucursalesTable.nombre
    },
    precioCompra: detallesProductoTable.precioCompra,
    porcentajeGanancia: detallesProductoTable.porcentajeGanancia,
    precioVenta: detallesProductoTable.precioVenta,
    precioOferta: detallesProductoTable.precioOferta,
    stock: detallesProductoTable.stock,
    stockBajo: detallesProductoTable.stockBajo,
    liquidacion: detallesProductoTable.liquidacion
  }

  private async getByIdSortColumn(idProducto: SucursalIdType) {
    const productos = await db
      .select(this.selectFields)
      .from(productosTable)
      .innerJoin(coloresTable, eq(coloresTable.id, productosTable.colorId))
      .innerJoin(
        categoriasTable,
        eq(categoriasTable.id, productosTable.categoriaId)
      )
      .innerJoin(marcasTable, eq(marcasTable.id, productosTable.marcaId))
      .where(eq(productosTable.id, idProducto))

    if (productos.length < 1) {
      throw CustomError.badRequest(
        `No se encontro ningun producto con el ID: ${idProducto} `
      )
    }
    const SucursalesInfo = await db
      .select(this.fieldsSucursales)
      .from(sucursalesTable)
      .innerJoin(
        detallesProductoTable,
        eq(detallesProductoTable.sucursalId, sucursalesTable.id)
      )
      .where(eq(detallesProductoTable.productoId, idProducto))
    const [producto] = productos

    return {
      ...producto,
      SucursalesInfo
    }
  }

  async execute(idProducto: SucursalIdType) {
    const producto = await this.getByIdSortColumn(idProducto)
    return producto
  }
}
