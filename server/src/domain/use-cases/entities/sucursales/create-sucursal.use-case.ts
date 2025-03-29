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
    const conditionals = []

    if (createSucursalDto.serieFactura != null) {
      conditionals.push(
        ilike(sucursalesTable.serieFactura, createSucursalDto.serieFactura)
      )
    }

    if (createSucursalDto.serieBoleta != null) {
      conditionals.push(
        ilike(sucursalesTable.serieBoleta, createSucursalDto.serieBoleta)
      )
    }

    if (createSucursalDto.codigoEstablecimiento != null) {
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
        serieFactura: sucursalesTable.serieFactura,
        serieBoleta: sucursalesTable.serieBoleta,
        codigoEstablecimiento: sucursalesTable.codigoEstablecimiento
      })
      .from(sucursalesTable)
      .where(or(...conditionals))

    for (const sucursal of sucursales) {
      if (
        createSucursalDto.serieFactura != null &&
        sucursal.serieFactura === createSucursalDto.serieFactura
      ) {
        throw CustomError.badRequest(
          `Ya existe una sucursal con esa serie de factura: '${createSucursalDto.serieFactura}'`
        )
      }
      if (
        createSucursalDto.serieBoleta != null &&
        sucursal.serieBoleta === createSucursalDto.serieBoleta
      ) {
        throw CustomError.badRequest(
          `Ya existe una sucursal con esa serie de boleta: '${createSucursalDto.serieBoleta}'`
        )
      }
      if (
        createSucursalDto.codigoEstablecimiento != null &&
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
        serieFactura: createSucursalDto.serieFactura,
        numeroFacturaInicial: createSucursalDto.numeroFacturaInicial,
        serieBoleta: createSucursalDto.serieBoleta,
        numeroBoletaInicial: createSucursalDto.numeroBoletaInicial,
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
