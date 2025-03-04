import { marcasTable } from '@/db/schema'
import { db } from '@db/connection'
import type { CreateMarcasDto } from '@/domain/dtos/entities/marcas/create-marcas.dto'

interface CreateMarcasUseCase {
  execute: (dto: CreateMarcasDto) => Promise<any>
}

export class CreateMarcas implements CreateMarcasUseCase {
  async execute(dto: CreateMarcasDto): Promise<any> {
    const marca = await db
      .insert(marcasTable)
      .values({
        nombre: dto.nombre,
        descripcion: dto.descripcion
      })
      .returning()

    return marca[0]
  }
}
