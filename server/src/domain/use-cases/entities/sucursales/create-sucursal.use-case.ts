import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { sucursalesTable } from '@/db/schema'
import type { CreateSucursalDto } from '@/domain/dtos/entities/sucursales/create-sucursal.dto'
import { SucursalEntityMapper } from '@/domain/mappers/sucursal-entity.mapper'
import { db } from '@db/connection'
import { ilike } from 'drizzle-orm'

export class CreateSucursal {
  private readonly authPayload: AuthPayload
  private readonly permissionCreateAny = permissionCodes.sucursales.createAny

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private async createSucursal(createSucursalDto: CreateSucursalDto) {
    const sucursalesWithSameName = await db
      .select()
      .from(sucursalesTable)
      .where(ilike(sucursalesTable.nombre, createSucursalDto.nombre))

    if (sucursalesWithSameName.length > 0) {
      throw CustomError.badRequest(
        `Ya existe una sucursal con ese nombre: '${createSucursalDto.nombre}'`
      )
    }

    const insertedSucursalResult = await db
      .insert(sucursalesTable)
      .values({
        nombre: createSucursalDto.nombre,
        direccion: createSucursalDto.direccion,
        sucursalCentral: createSucursalDto.sucursalCentral
      })
      .returning()

    if (insertedSucursalResult.length <= 0) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar crear la sucursal'
      )
    }

    const [sucursal] = insertedSucursalResult

    return sucursal
  }

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionCreateAny]
    )

    if (
      !validPermissions.some(
        (permission) => permission.codigoPermiso === this.permissionCreateAny
      )
    ) {
      throw CustomError.forbidden()
    }
  }

  async execute(createSucursalDto: CreateSucursalDto) {
    await this.validatePermissions()

    const sucursal = await this.createSucursal(createSucursalDto)

    const mappedSucursal = SucursalEntityMapper.fromObject(sucursal)

    return mappedSucursal
  }
}
