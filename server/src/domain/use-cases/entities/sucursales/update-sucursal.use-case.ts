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

    if (updateSucursalDto.serieFactura != null) {
      conditionals.push(
        ilike(sucursalesTable.serieFactura, updateSucursalDto.serieFactura)
      )
    }

    if (updateSucursalDto.serieBoleta != null) {
      conditionals.push(
        ilike(sucursalesTable.serieBoleta, updateSucursalDto.serieBoleta)
      )
    }

    if (updateSucursalDto.codigoEstablecimiento != null) {
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
        serieFactura: sucursalesTable.serieFactura,
        serieBoleta: sucursalesTable.serieBoleta,
        codigoEstablecimiento: sucursalesTable.codigoEstablecimiento
      })
      .from(sucursalesTable)
      .where(or(...conditionals))

    for (const sucursal of sucursales) {
      if (
        updateSucursalDto.serieFactura != null &&
        sucursal.serieFactura === updateSucursalDto.serieFactura
      ) {
        throw CustomError.badRequest(
          `Ya existe una sucursal con esa serie de factura: '${updateSucursalDto.serieFactura}'`
        )
      }
      if (
        updateSucursalDto.serieBoleta != null &&
        sucursal.serieBoleta === updateSucursalDto.serieBoleta
      ) {
        throw CustomError.badRequest(
          `Ya existe una sucursal con esa serie de boleta: '${updateSucursalDto.serieBoleta}'`
        )
      }
      if (
        updateSucursalDto.codigoEstablecimiento != null &&
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
      updateSucursalDto.nombre != null ||
      updateSucursalDto.serieFactura != null ||
      updateSucursalDto.serieBoleta != null ||
      updateSucursalDto.codigoEstablecimiento != null
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
        serieFactura: updateSucursalDto.serieFactura,
        numeroFacturaInicial: updateSucursalDto.numeroFacturaInicial,
        serieBoleta: updateSucursalDto.serieBoleta,
        numeroBoletaInicial: updateSucursalDto.numeroBoletaInicial,
        codigoEstablecimiento: updateSucursalDto.codigoEstablecimiento,
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
