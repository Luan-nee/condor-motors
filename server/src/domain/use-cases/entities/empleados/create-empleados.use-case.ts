import { CustomError } from '@/core/errors/custom.error'
import { empleadosTable, sucursalesTable } from '@/db/schema'
import type { CreateEmpleadoDto } from '@/domain/dtos/entities/empleados/create-empleado.dto'
import { db } from '@db/connection'
import { eq } from 'drizzle-orm'
import path from 'node:path'
import sharp from 'sharp'

export class CreateEmpleado {
  // private readonly authPayload: AuthPayload
  // private readonly permissionAny = permissionCodes.empleados.createAny

  // constructor(authPayload: AuthPayload) {
  //   this.authPayload = authPayload
  // }

  constructor(private readonly publicStoragePath: string) {}

  private async createEmpleado(
    createEmpleadoDto: CreateEmpleadoDto,
    file: Express.Multer.File | undefined
  ) {
    const pathFoto = file !== undefined ? await this.saveFoto(file) : undefined
    const sueldoString = createEmpleadoDto.sueldo?.toFixed(2)

    const insertedEmpleadoResult = await db
      .insert(empleadosTable)
      .values({
        nombre: createEmpleadoDto.nombre,
        apellidos: createEmpleadoDto.apellidos,
        activo: createEmpleadoDto.activo,
        dni: createEmpleadoDto.dni,
        pathFoto,
        celular: createEmpleadoDto.celular,
        horaInicioJornada: createEmpleadoDto.horaInicioJornada,
        horaFinJornada: createEmpleadoDto.horaFinJornada,
        fechaContratacion: createEmpleadoDto.fechaContratacion,
        sueldo: sueldoString,
        sucursalId: createEmpleadoDto.sucursalId
      })
      .returning({ id: empleadosTable.id, pathFoto: empleadosTable.pathFoto })

    if (insertedEmpleadoResult.length < 1) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar registrar el empleado'
      )
    }

    return insertedEmpleadoResult
  }

  private async validateRelated(createEmpleadoDto: CreateEmpleadoDto) {
    const results = await db
      .select({
        sucursalId: sucursalesTable.id
      })
      .from(sucursalesTable)
      .where(eq(sucursalesTable.id, createEmpleadoDto.sucursalId))

    if (results.length < 1) {
      throw CustomError.badRequest('La sucursal ingresada no existe')
    }
  }

  async saveFoto(file: Express.Multer.File) {
    try {
      const metadata = await sharp(file.buffer).metadata()

      if (
        metadata.width == null ||
        metadata.height == null ||
        metadata.width > 2400 ||
        metadata.height > 2400
      ) {
        throw CustomError.badRequest('Image is too large')
      }

      const uuid = crypto.randomUUID()
      const name = `${uuid}.webp`

      const filepath = path.join(this.publicStoragePath, 'static', name)

      await sharp(file.buffer)
        .resize(800, 800)
        .toFormat('webp')
        .webp({ quality: 80 })
        .toFile(filepath)

      return `/static/${name}`
    } catch (error) {
      if (error instanceof CustomError) {
        throw error
      }

      throw CustomError.internalServer()
    }
  }

  // private async validatePermissions() {
  //   const validPermissions = await AccessControl.verifyPermissions(
  //     this.authPayload,
  //     [this.permissionAny]
  //   )

  //   const hasPermissionAny = validPermissions.some(
  //     (permission) => permission.codigoPermiso === this.permissionAny
  //   )

  //   if (!hasPermissionAny) {
  //     throw CustomError.forbidden()
  //   }
  // }

  async execute(
    createEmpleadoDto: CreateEmpleadoDto,
    file: Express.Multer.File | undefined
  ) {
    // await this.validatePermissions()

    await this.validateRelated(createEmpleadoDto)
    const empleado = await this.createEmpleado(createEmpleadoDto, file)

    return empleado
  }
}
