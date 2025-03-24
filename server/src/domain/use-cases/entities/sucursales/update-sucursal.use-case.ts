import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { sucursalesTable } from '@/db/schema'
import type { UpdateSucursalDto } from '@/domain/dtos/entities/sucursales/update-sucursal.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { db } from '@db/connection'
import { eq, ilike, or } from 'drizzle-orm'

export class UpdateSucursal {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.sucursales.updateAny

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private getConditionals(updateSucursalDto: UpdateSucursalDto) {
    const conditionals = []

    if (updateSucursalDto.nombre !== undefined) {
      conditionals.push(ilike(sucursalesTable.nombre, updateSucursalDto.nombre))
    }

    if (updateSucursalDto.serieBoletaSucursal !== undefined) {
      conditionals.push(
        ilike(
          sucursalesTable.serieBoletaSucursal,
          updateSucursalDto.serieBoletaSucursal
        )
      )
    }

    if (updateSucursalDto.serieFacturaSucursal !== undefined) {
      conditionals.push(
        ilike(
          sucursalesTable.serieFacturaSucursal,
          updateSucursalDto.serieFacturaSucursal
        )
      )
    }

    if (updateSucursalDto.codigoEstablecimiento !== undefined) {
      conditionals.push(
        ilike(
          sucursalesTable.codigoEstablecimiento,
          updateSucursalDto.codigoEstablecimiento
        )
      )
    }

    return conditionals
  }

  private async checkDuplicated(updateSucursalDto: UpdateSucursalDto) {
    const conditionals = this.getConditionals(updateSucursalDto)

    const sucursales = await db
      .select({
        id: sucursalesTable.id,
        serieFacturaSucursal: sucursalesTable.serieFacturaSucursal,
        serieBoletaSucursal: sucursalesTable.serieBoletaSucursal,
        codigoEstablecimiento: sucursalesTable.codigoEstablecimiento
      })
      .from(sucursalesTable)
      .where(or(...conditionals))

    if (sucursales.length > 0) {
      throw CustomError.badRequest(
        `Ya existe una sucursal con ese nombre: '${updateSucursalDto.nombre}'`
      )
    }

    for (const sucursal of sucursales) {
      if (
        updateSucursalDto.serieFacturaSucursal !== undefined &&
        sucursal.serieFacturaSucursal === updateSucursalDto.serieFacturaSucursal
      ) {
        throw CustomError.badRequest(
          `Ya existe una sucursal con esa serie de factura: '${updateSucursalDto.serieFacturaSucursal}'`
        )
      }
      if (
        updateSucursalDto.serieBoletaSucursal !== undefined &&
        sucursal.serieBoletaSucursal === updateSucursalDto.serieBoletaSucursal
      ) {
        throw CustomError.badRequest(
          `Ya existe una sucursal con esa serie de boleta: '${updateSucursalDto.serieFacturaSucursal}'`
        )
      }
      if (
        updateSucursalDto.codigoEstablecimiento !== undefined &&
        sucursal.codigoEstablecimiento ===
          updateSucursalDto.codigoEstablecimiento
      ) {
        throw CustomError.badRequest(
          `Ya existe una sucursal con ese codigo de establecimiento: '${updateSucursalDto.codigoEstablecimiento}'`
        )
      }
    }
  }

  private async updateSucursal(
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

    if (
      updateSucursalDto.nombre !== undefined ||
      updateSucursalDto.serieFacturaSucursal !== undefined ||
      updateSucursalDto.serieBoletaSucursal !== undefined ||
      updateSucursalDto.codigoEstablecimiento !== undefined
    ) {
      await this.checkDuplicated(updateSucursalDto)
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
      .returning({ id: sucursalesTable.id })

    if (updatedSucursalResult.length < 1) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar actualizar los datos de la sucursal'
      )
    }

    const [sucursal] = updatedSucursalResult

    return sucursal
  }

  private async validatePermissions() {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny]
    )

    let hasPermissionAny = false

    for (const permission of validPermissions) {
      if (permission.codigoPermiso === this.permissionAny) {
        hasPermissionAny = true
      }

      if (hasPermissionAny) {
        return
      }
    }

    throw CustomError.forbidden()
  }

  async execute(
    updateSucursalDto: UpdateSucursalDto,
    numericIdDto: NumericIdDto
  ) {
    await this.validatePermissions()

    const sucursal = this.updateSucursal(updateSucursalDto, numericIdDto)

    return await sucursal
  }
}
