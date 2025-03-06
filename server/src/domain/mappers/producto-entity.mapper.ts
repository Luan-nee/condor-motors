import type { ProductoEntity } from '@/types/schemas'
import { RelacionadosProductoEntityMapper } from './relacionados-producto-entity.mapper'

interface parseDataArgs {
  id: ProductoEntity['id']
  unidadId: ProductoEntity['unidadId']
  categoriaId: ProductoEntity['categoriaId']
  marcaId: ProductoEntity['marcaId']
  precioBase: ProductoEntity['precioBase']
  precioMayorista: ProductoEntity['precioMayorista']
  precioOferta: ProductoEntity['precioOferta']
}

export class ProductoEntityMapper {
  private static parseData(input: parseDataArgs) {
    const precioBase =
      input.precioBase !== null
        ? parseFloat(input.precioBase)
        : input.precioBase

    const precioMayorista =
      input.precioMayorista !== null
        ? parseFloat(input.precioMayorista)
        : input.precioMayorista

    const precioOferta =
      input.precioOferta !== null
        ? parseFloat(input.precioOferta)
        : input.precioOferta

    return {
      id: String(input.id),
      unidadId: String(input.unidadId),
      categoriaId: String(input.categoriaId),
      marcaId: String(input.marcaId),
      precioBase,
      precioMayorista,
      precioOferta
    }
  }

  static fromObject(input: ProductoEntity) {
    const { relacionados } = input

    const mappedRelacionados =
      RelacionadosProductoEntityMapper.fromObject(relacionados)

    const parsedData = this.parseData(input)

    return {
      id: parsedData.id,
      nombre: input.nombre,
      descripcion: input.descripcion,
      sku: input.sku,
      maxDiasSinReabastecer: input.maxDiasSinReabastecer,
      unidadId: parsedData.unidadId,
      categoriaId: parsedData.categoriaId,
      marcaId: parsedData.marcaId,
      precioBase: parsedData.precioBase,
      precioMayorista: parsedData.precioMayorista,
      precioOferta: parsedData.precioOferta,
      stock: input.stock,
      relacionados: mappedRelacionados,
      fechaCreacion: input.fechaCreacion,
      fechaActualizacion: input.fechaActualizacion
    }
  }
}
