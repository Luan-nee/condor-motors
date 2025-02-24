import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { sucursalesTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { eq } from 'drizzle-orm'

export class DeleteSucursal {
  // eslint-disable-next-line @typescript-eslint/class-methods-use-this
  async execute(numericIdDto: NumericIdDto) {
    const sucursales = await db
      .delete(sucursalesTable)
      .where(eq(sucursalesTable.id, numericIdDto.id))
      .returning({ id: sucursalesTable.id })

    if (sucursales.length <= 0) {
      throw CustomError.badRequest(
        `No se pudo eliminar la sucursal con el id '${numericIdDto.id}' (No encontrada)`
      )
    }

    const [sucursal] = sucursales

    return sucursal
  }
}
