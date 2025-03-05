import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  categoriasTable,
  marcasTable,
  productosTable,
  unidadesTable
} from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { ProductoEntityMapper } from '@/domain/mappers/producto-entity.mapper'
import { eq } from 'drizzle-orm'

export class GetProductoById {
  private readonly authPayload: AuthPayload
  private readonly permissionGetAny = permissionCodes.productos.getAny
  private readonly selectFields = {
    id: productosTable.id,
    sku: productosTable.sku,
    nombre: productosTable.nombre,
    descripcion: productosTable.descripcion,
    maxDiasSinReabastecer: productosTable.maxDiasSinReabastecer,
    unidadId: productosTable.unidadId,
    categoriaId: productosTable.categoriaId,
    marcaId: productosTable.marcaId,
    fechaCreacion: productosTable.fechaCreacion,
    fechaActualizacion: productosTable.fechaActualizacion,
    relacionados: {
      unidadNombre: unidadesTable.nombre,
      categoriaNombre: categoriasTable.nombre,
      marcaNombre: marcasTable.nombre
    }
  }

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async getProductoById(numericIdDto: NumericIdDto) {
    const productos = await db
      .select(this.selectFields)
      .from(productosTable)
      .innerJoin(unidadesTable, eq(unidadesTable.id, productosTable.unidadId))
      .innerJoin(
        categoriasTable,
        eq(categoriasTable.id, productosTable.categoriaId)
      )
      .innerJoin(marcasTable, eq(marcasTable.id, productosTable.marcaId))
      .where(eq(productosTable.id, numericIdDto.id))

    if (productos.length < 1) {
      throw CustomError.badRequest(
        `No se encontró ningún producto con el id ${numericIdDto.id}`
      )
    }

    const [producto] = productos

    return producto
  }

  async execute(numericIdDto: NumericIdDto) {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionGetAny]
    )

    if (
      !validPermissions.some(
        (permission) => permission.codigoPermiso === this.permissionGetAny
      )
    ) {
      throw CustomError.forbidden(
        'No tienes los suficientes permisos para realizar esta acción'
      )
    }

    const producto = await this.getProductoById(numericIdDto)

    const mappedProducto = ProductoEntityMapper.fromObject(producto)

    return mappedProducto
  }
}
