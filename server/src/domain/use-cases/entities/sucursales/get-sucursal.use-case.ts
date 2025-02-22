import { db } from '@/db/connection'
import { sucursalesTable } from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { CustomError } from '@/domain/errors/custom.error'
import { SucursalEntityMapper } from '@/domain/mappers/sucursal-entity.mapper'
import { eq } from 'drizzle-orm'

export class GetSucursal {
  // eslint-disable-next-line @typescript-eslint/class-methods-use-this
  async execute(numericIdDto: NumericIdDto) {
    const sucursales = await db
      .select()
      .from(sucursalesTable)
      .where(eq(sucursalesTable.id, numericIdDto.id))

    if (sucursales.length <= 0) {
      throw CustomError.badRequest(
        `No se encontró ninguna sucursal con el id '${numericIdDto.id}'`
      )
    }

    const [sucursal] = sucursales

    const mappedSucursal =
      SucursalEntityMapper.sucursalEntityFromObject(sucursal)

    return mappedSucursal
  }
}
