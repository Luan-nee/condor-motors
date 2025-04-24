import { CustomError } from '@/core/errors/custom.error'
import {
  cuentasEmpleadosTable,
  empleadosTable,
  sucursalesTable
} from '@/db/schema'
import type { UpdateEmpleadoDto } from '@/domain/dtos/entities/empleados/update-empleado.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { db } from '@db/connection'
import { eq } from 'drizzle-orm'
import { stat, unlink } from 'node:fs/promises'
import path from 'node:path'
import sharp from 'sharp'

export class UpdateEmpleado {
  // private readonly authPayload: AuthPayload
  // private readonly permissionAny = permissionCodes.empleados.updateAny
  // private readonly permissionSelf = permissionCodes.empleados.updateSelf
  // constructor(authPayload: AuthPayload) {
  //   this.authPayload = authPayload
  // }

  constructor(private readonly publicStoragePath: string) {}

  // eslint-disable-next-line complexity
  private async updateEmpleado(
    updateEmpleadoDto: UpdateEmpleadoDto,
    numericIdDto: NumericIdDto,
    file: Express.Multer.File | undefined
  ) {
    const empleados = await db
      .select({
        id: empleadosTable.id,
        eliminable: cuentasEmpleadosTable.eliminable,
        pathFoto: empleadosTable.pathFoto
      })
      .from(empleadosTable)
      .leftJoin(
        cuentasEmpleadosTable,
        eq(empleadosTable.id, cuentasEmpleadosTable.empleadoId)
      )
      .where(eq(empleadosTable.id, numericIdDto.id))

    if (empleados.length < 1) {
      throw CustomError.notFound(
        'Los datos del colaborador no se pudieron actualizar (no encontrado)'
      )
    }

    const [currentEmpleado] = empleados

    if (updateEmpleadoDto.activo != null && !updateEmpleadoDto.activo) {
      if (currentEmpleado.eliminable != null && !currentEmpleado.eliminable) {
        throw CustomError.badRequest(
          'Este colaborador no puede ser desactivado'
        )
      }
    }

    const pathFoto = file !== undefined ? await this.saveFoto(file) : undefined

    if (file !== undefined && currentEmpleado.pathFoto != null) {
      const filePath = path.join(
        this.publicStoragePath,
        currentEmpleado.pathFoto
      )

      let fileExists = true

      try {
        await stat(filePath)
      } catch {
        fileExists = false
      }

      if (fileExists) {
        await unlink(filePath)
          .then()
          .catch(() => {
            throw CustomError.internalServer(
              `Ha ocurrido un error al intentar actualizar la foto del colaborador: ${JSON.stringify(currentEmpleado)}`
            )
          })
      }
    }

    const sueldoString = updateEmpleadoDto.sueldo?.toFixed(2)

    const updateEmpleadoResultado = await db
      .update(empleadosTable)
      .set({
        nombre: updateEmpleadoDto.nombre,
        apellidos: updateEmpleadoDto.apellidos,
        activo: updateEmpleadoDto.activo,
        dni: updateEmpleadoDto.dni,
        pathFoto,
        celular: updateEmpleadoDto.celular,
        horaInicioJornada: updateEmpleadoDto.horaInicioJornada,
        horaFinJornada: updateEmpleadoDto.horaFinJornada,
        fechaContratacion: updateEmpleadoDto.fechaContratacion,
        sueldo: sueldoString,
        sucursalId: updateEmpleadoDto.sucursalId
      })
      .where(eq(empleadosTable.id, numericIdDto.id))
      .returning({ id: empleadosTable.id })

    if (updateEmpleadoResultado.length <= 0) {
      throw CustomError.internalServer(
        'Ha ocurrido un error al intentar actualizar los datos del empleado'
      )
    }

    const [empleado] = updateEmpleadoResultado

    return empleado
  }

  private async validateRelacionados(
    updateEmpleadoDto: UpdateEmpleadoDto,
    numericIdDto: NumericIdDto
  ) {
    const whereCondition =
      updateEmpleadoDto.sucursalId !== undefined
        ? eq(sucursalesTable.id, updateEmpleadoDto.sucursalId)
        : undefined

    const results = await db
      .select({
        sucursalId: sucursalesTable.id,
        empleadoId: empleadosTable.id
      })
      .from(sucursalesTable)
      .leftJoin(empleadosTable, eq(empleadosTable.id, numericIdDto.id))
      .where(whereCondition)

    if (results.length < 1) {
      throw CustomError.badRequest('La sucursal ingresada no existe')
    }

    if (!results.some((result) => result.empleadoId === numericIdDto.id)) {
      throw CustomError.badRequest('El empleado especificado no existe')
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
    updateEmpleadoDto: UpdateEmpleadoDto,
    numericIdDto: NumericIdDto,
    file: Express.Multer.File | undefined
  ) {
    // await this.validatePermissions()
    await this.validateRelacionados(updateEmpleadoDto, numericIdDto)

    const empleado = await this.updateEmpleado(
      updateEmpleadoDto,
      numericIdDto,
      file
    )

    return empleado
  }
}
