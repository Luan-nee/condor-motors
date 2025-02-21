/* eslint-disable @typescript-eslint/class-methods-use-this */
import { sucursalesTable } from '@/db/schema'
import type { CreateSucursalDto } from '@/domain/dtos/entities/sucursales/create-sucursal.dto'
import { CustomError } from '@/domain/errors/custom.error'
import { SucursalEntityMapper } from '@/domain/mappers/sucursal-entity.mapper'
import { db } from '@db/connection'
import { sql } from 'drizzle-orm'

export class CreateSucursal {
  async execute(createSucursalDto: CreateSucursalDto) {
    const sucursalesWithSameName = await db
      .select()
      .from(sucursalesTable)
      .where(
        sql`lower(${sucursalesTable.nombre}) = lower(${createSucursalDto.nombre})`
      )

    if (sucursalesWithSameName.length > 0) {
      throw CustomError.badRequest(
        `Ya existe una sucursal con ese nombre: '${createSucursalDto.nombre}'`
      )
    }

    const insertedSucursalResult = await db
      .insert(sucursalesTable)
      .values({
        nombre: createSucursalDto.nombre,
        ubicacion: createSucursalDto.ubicacion,
        sucursalCentral: createSucursalDto.sucursalCentral,
        fechaRegistro: new Date()
      })
      .returning()

    if (insertedSucursalResult.length <= 0) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar crear la sucursal'
      )
    }

    const [sucursal] = insertedSucursalResult

    const mappedSucursal =
      SucursalEntityMapper.sucursalEntityFromObject(sucursal)

    return mappedSucursal
  }
}
