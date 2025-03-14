import type { ProductoEntity } from '@/types/schemas'
import { RelacionadosProductoEntityMapper } from './relacionados-producto-entity.mapper'

interface parseDataArgs {
  id: ProductoEntity['id']
  colorId: ProductoEntity['colorId']
  categoriaId: ProductoEntity['categoriaId']
  marcaId: ProductoEntity['marcaId']
  precioCompra: ProductoEntity['precioCompra']
  precioVenta: ProductoEntity['precioVenta']
  precioOferta: ProductoEntity['precioOferta']
}

export class ProductoEntityMapper {
  private static parseData(input: parseDataArgs) {
    const precioCompra =
      input.precioCompra !== null
        ? parseFloat(input.precioCompra)
        : input.precioCompra

    const precioVenta =
      input.precioVenta !== null
        ? parseFloat(input.precioVenta)
        : input.precioVenta

    const precioOferta =
      input.precioOferta !== null
        ? parseFloat(input.precioOferta)
        : input.precioOferta

    return {
      id: String(input.id),
      colorId: String(input.colorId),
      categoriaId: String(input.categoriaId),
      marcaId: String(input.marcaId),
      precioCompra,
      precioVenta,
      precioOferta
    }
  }

  static fromObject(input: ProductoEntity) {
    const { relacionados } = input

    const mappedRelacionados =
      RelacionadosProductoEntityMapper.fromObject(relacionados)

    const parsedData = this.parseData({
      id: input.id,
      colorId: input.colorId,
      categoriaId: input.categoriaId,
      marcaId: input.marcaId,
      precioCompra: input.precioCompra,
      precioVenta: input.precioVenta,
      precioOferta: input.precioOferta
    })

    return {
      id: parsedData.id,
      nombre: input.nombre,
      descripcion: input.descripcion,
      maxDiasSinReabastecer: input.maxDiasSinReabastecer,
      stockMinimo: input.stockMinimo,
      cantidadMinimaDescuento: input.cantidadMinimaDescuento,
      cantidadGratisDescuento: input.cantidadGratisDescuento,
      porcentajeDescuento: input.porcentajeDescuento,
      colorId: parsedData.colorId,
      categoriaId: parsedData.categoriaId,
      marcaId: parsedData.marcaId,
      precioCompra: parsedData.precioCompra,
      precioVenta: parsedData.precioVenta,
      precioOferta: parsedData.precioOferta,
      stock: input.stock,
      relacionados: mappedRelacionados,
      fechaCreacion: input.fechaCreacion,
      fechaActualizacion: input.fechaActualizacion
    }
  }
}
