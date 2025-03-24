import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { sucursalesTable } from '@/db/schema'
import type { CreateSucursalDto } from '@/domain/dtos/entities/sucursales/create-sucursal.dto'
import { db } from '@db/connection'
import { ilike, or } from 'drizzle-orm'

export class CreateSucursal {
  private readonly authPayload: AuthPayload
  private readonly permissionAny = permissionCodes.sucursales.createAny

  constructor(authPayload: AuthPayload) {
    this.authPayload = authPayload
  }

  private getConditionals(createSucursalDto: CreateSucursalDto) {
    const conditionals = [
      ilike(sucursalesTable.nombre, createSucursalDto.nombre)
    ]

    if (createSucursalDto.serieBoletaSucursal !== undefined) {
      conditionals.push(
        ilike(
          sucursalesTable.serieBoletaSucursal,
          createSucursalDto.serieBoletaSucursal
        )
      )
    }

    if (createSucursalDto.serieFacturaSucursal !== undefined) {
      conditionals.push(
        ilike(
          sucursalesTable.serieFacturaSucursal,
          createSucursalDto.serieFacturaSucursal
        )
      )
    }

    if (createSucursalDto.codigoEstablecimiento !== undefined) {
      conditionals.push(
        ilike(
          sucursalesTable.codigoEstablecimiento,
          createSucursalDto.codigoEstablecimiento
        )
      )
    }

    return conditionals
  }

  private async checkDuplicated(createSucursalDto: CreateSucursalDto) {
    const conditionals = this.getConditionals(createSucursalDto)

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
        `Ya existe una sucursal con ese nombre: '${createSucursalDto.nombre}'`
      )
    }

    for (const sucursal of sucursales) {
      if (
        createSucursalDto.serieFacturaSucursal !== undefined &&
        sucursal.serieFacturaSucursal === createSucursalDto.serieFacturaSucursal
      ) {
        throw CustomError.badRequest(
          `Ya existe una sucursal con esa serie de factura: '${createSucursalDto.serieFacturaSucursal}'`
        )
      }
      if (
        createSucursalDto.serieBoletaSucursal !== undefined &&
        sucursal.serieBoletaSucursal === createSucursalDto.serieBoletaSucursal
      ) {
        throw CustomError.badRequest(
          `Ya existe una sucursal con esa serie de boleta: '${createSucursalDto.serieFacturaSucursal}'`
        )
      }
      if (
        createSucursalDto.codigoEstablecimiento !== undefined &&
        sucursal.codigoEstablecimiento ===
          createSucursalDto.codigoEstablecimiento
      ) {
        throw CustomError.badRequest(
          `Ya existe una sucursal con ese codigo de establecimiento: '${createSucursalDto.codigoEstablecimiento}'`
        )
      }
    }
  }

  private async createSucursal(createSucursalDto: CreateSucursalDto) {
    const insertedSucursalResult = await db
      .insert(sucursalesTable)
      .values({
        nombre: createSucursalDto.nombre,
        direccion: createSucursalDto.direccion,
        sucursalCentral: createSucursalDto.sucursalCentral,
        serieFacturaSucursal: createSucursalDto.serieFacturaSucursal,
        serieBoletaSucursal: createSucursalDto.serieBoletaSucursal,
        codigoEstablecimiento: createSucursalDto.codigoEstablecimiento
      })
      .returning({ id: sucursalesTable.id })

    if (insertedSucursalResult.length < 1) {
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

  async execute(createSucursalDto: CreateSucursalDto) {
    await this.validatePermissions()
    await this.checkDuplicated(createSucursalDto)

    const sucursal = await this.createSucursal(createSucursalDto)

    return sucursal
  }
}
