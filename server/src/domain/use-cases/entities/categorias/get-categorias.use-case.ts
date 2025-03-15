import { db } from '@/db/connection'
import { categoriasTable } from '@/db/schema'
import type { QueriesDto } from '@/domain/dtos/query-params/queries.dto'

export class GetCategorias {
  private readonly authPayload: AuthPayload
  private readonly selectFields = {
    id: categoriasTable.id,
    nombre: categoriasTable.nombre,
    descripcion: categoriasTable.descripcion
  }

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async getAnyCategorias(queriesDto: QueriesDto) {
    return await db.select().from(categoriasTable).limit(queriesDto.page_size)
  }

  private async getCategorias(queriesDto: QueriesDto) {
    const categorias = await this.getAnyCategorias(queriesDto)
    if (categorias.length < 1) {
      return []
    }

    return categorias
  }

  async execute(queriesDto: QueriesDto) {
    const categorias = await this.getCategorias(queriesDto)
    return categorias
  }
}
