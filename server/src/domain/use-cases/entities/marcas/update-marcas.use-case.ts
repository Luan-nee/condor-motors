import { marcasTable } from '@/db/schema'
import { db } from '@db/connection'
import type { UpdateMarcasDto } from '@/domain/dtos/entities/marcas/update-marcas.dto'
import { eq } from 'drizzle-orm'

interface UpdateMarcasUseCase {
  execute: (dto: UpdateMarcasDto) => Promise<any>
}

export class UpdateMarcas implements UpdateMarcasUseCase {
  async execute(dto: UpdateMarcasDto): Promise<any> {
    const marca = await db
      .update(marcasTable)
      .set({
        nombre: dto.nombre,
        descripcion: dto.descripcion
      })
      .where(eq(marcasTable.id, dto.id))
      .returning()

    return marca[0]
  }
}
