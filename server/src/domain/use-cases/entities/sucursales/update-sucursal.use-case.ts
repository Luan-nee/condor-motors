import { CustomError } from '@/core/errors/custom.error'
import { sucursalesTable } from '@/db/schema'
import type { UpdateSucursalDto } from '@/domain/dtos/entities/sucursales/update-sucursal.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { SucursalEntityMapper } from '@/domain/mappers/sucursal-entity.mapper'
import { db } from '@db/connection'
import { eq, ilike } from 'drizzle-orm'

export class UpdateSucursal {
  // eslint-disable-next-line @typescript-eslint/class-methods-use-this
  async execute(
    updateSucursalDto: UpdateSucursalDto,
    numericIdDto: NumericIdDto
  ) {
    const sucursales = await db
      .select()
      .from(sucursalesTable)
      .where(eq(sucursalesTable.id, numericIdDto.id))

    if (sucursales.length <= 0) {
      throw CustomError.badRequest(
        `No se encontró ninguna sucursal con el id '${numericIdDto.id}'`
      )
    }

    if (updateSucursalDto.nombre !== undefined) {
      const sucursalesWithSameName = await db
        .select()
        .from(sucursalesTable)
        .where(ilike(sucursalesTable.nombre, updateSucursalDto.nombre))

      if (sucursalesWithSameName.length > 0) {
        throw CustomError.badRequest(
          `Ya existe una sucursal con ese nombre: '${updateSucursalDto.nombre}'`
        )
      }
    }

    const now = new Date()

    const updatedSucursalResult = await db
      .update(sucursalesTable)
      .set({
        nombre: updateSucursalDto.nombre,
        direccion: updateSucursalDto.direccion,
        sucursalCentral: updateSucursalDto.sucursalCentral,
        fechaActualizacion: now
      })
      .where(eq(sucursalesTable.id, numericIdDto.id))
      .returning()

    if (updatedSucursalResult.length <= 0) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar actualizar los datos de la sucursal'
      )
    }

    const [sucursal] = updatedSucursalResult

    const mappedSucursal =
      SucursalEntityMapper.sucursalEntityFromObject(sucursal)

    return mappedSucursal
  }
}
