import type { ProductoEntity } from '@/types/schemas'
import { RelacionadosProductoEntityMapper } from './relacionados-producto-entity.mapper'

export class ProductoEntityMapper {
  static fromObject(input: ProductoEntity) {
    const { relacionados } = input

    const mappedRelacionados =
      RelacionadosProductoEntityMapper.fromObject(relacionados)

    const parsedId = String(input.id)
    const parsedUnidadId = String(input.unidadId)
    const parsedCategoriaId = String(input.categoriaId)
    const parsedMarcaId = String(input.marcaId)

    return {
      id: parsedId,
      nombre: input.nombre,
      descripcion: input.descripcion,
      sku: input.sku,
      maxDiasSinReabastecer: input.maxDiasSinReabastecer,
      unidadId: parsedUnidadId,
      categoriaId: parsedCategoriaId,
      marcaId: parsedMarcaId,
      relacionados: mappedRelacionados,
      fechaCreacion: input.fechaCreacion,
      fechaActualizacion: input.fechaActualizacion
    }
  }
}
