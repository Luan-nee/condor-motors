import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { categoriasTable, productosTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { count, eq } from 'drizzle-orm'

export class GetCategoriaById {
  private readonly authpayload: AuthPayload

  private readonly selectFields = {
    id: categoriasTable.id,
    nombre: categoriasTable.nombre,
    descripcion: categoriasTable.descripcion,
    totalProductos: count(productosTable.id)
  }

  constructor(authpayload: AuthPayload) {
    this.authpayload = authpayload
  }

  private async getAnyCategoria(numericIdDto: NumericIdDto) {
    return await db
      .select(this.selectFields)
      .from(categoriasTable)
      .leftJoin(
        productosTable,
        eq(categoriasTable.id, productosTable.categoriaId)
      )
      .where(eq(categoriasTable.id, numericIdDto.id))
      .groupBy(categoriasTable.id)
  }

  private async getCategoriaById(numeric: NumericIdDto) {
    const categorias = await this.getAnyCategoria(numeric)
    if (categorias.length <= 0) {
      throw CustomError.badRequest(
        `No se Encontro ninguna categoria con el id ' ${numeric.id} ' ${this.authpayload.id} `
      )
    }
    const [categoria] = categorias
    return categoria
  }

  async execute(numericIdDto: NumericIdDto) {
    const categoria = await this.getCategoriaById(numericIdDto)
    return categoria
  }
}
