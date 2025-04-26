import { permissionCodes } from '@/consts'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { detallesProductoTable, productosTable } from '@/db/schema'
import type { UpdateProductoDto } from '@/domain/dtos/entities/productos/update-producto.dto'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq } from 'drizzle-orm'
import { stat, unlink } from 'node:fs/promises'
import path from 'node:path'
import sharp from 'sharp'

export class UpdateProducto {
  private readonly permissionAny = permissionCodes.productos.updateAny
  private readonly permissionRelated = permissionCodes.productos.updateRelated

  constructor(
    // private readonly authPayload: AuthPayload,
    private readonly permissions: Permission[],
    private readonly publicStoragePath: string,
    private readonly photosDirectory?: string
  ) {}

  // eslint-disable-next-line complexity
  private async updateProducto(
    numericIdDto: NumericIdDto,
    updateProductoDto: UpdateProductoDto,
    sucursalId: SucursalIdType,
    file: Express.Multer.File | undefined
  ) {
    const now = new Date()
    const mappedPrices = {
      precioCompra: updateProductoDto.precioCompra?.toFixed(2),
      precioVenta: updateProductoDto.precioVenta?.toFixed(2),
      precioOferta: updateProductoDto.precioOferta?.toFixed(2)
    }

    const productos = await db
      .select({ id: productosTable.id, pathFoto: productosTable.pathFoto })
      .from(productosTable)
      .where(eq(productosTable.id, numericIdDto.id))

    if (productos.length < 1) {
      throw CustomError.notFound('El producto no existe')
    }

    const [currentProducto] = productos

    const pathFoto = file !== undefined ? await this.saveFoto(file) : undefined

    if (file !== undefined && currentProducto.pathFoto != null) {
      const filePath = path.join(
        this.publicStoragePath,
        currentProducto.pathFoto
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
              `Ha ocurrido un error al intentar actualizar la foto del producto: ${JSON.stringify(currentProducto)}`
            )
          })
      }
    }

    try {
      await db.transaction(async (tx) => {
        const updatedProductos = await tx
          .update(productosTable)
          .set({
            nombre: updateProductoDto.nombre,
            descripcion: updateProductoDto.descripcion,
            maxDiasSinReabastecer: updateProductoDto.maxDiasSinReabastecer,
            stockMinimo: updateProductoDto.stockMinimo,
            cantidadMinimaDescuento: updateProductoDto.cantidadMinimaDescuento,
            cantidadGratisDescuento: updateProductoDto.cantidadGratisDescuento,
            porcentajeDescuento: updateProductoDto.porcentajeDescuento,
            pathFoto,
            colorId: updateProductoDto.colorId,
            categoriaId: updateProductoDto.categoriaId,
            marcaId: updateProductoDto.marcaId,
            fechaActualizacion: now
          })
          .where(eq(productosTable.id, numericIdDto.id))
          .returning({ id: productosTable.id })

        const updatedDetallesProducto = await tx
          .update(detallesProductoTable)
          .set({
            precioCompra: mappedPrices.precioCompra,
            precioVenta: mappedPrices.precioVenta,
            precioOferta: mappedPrices.precioOferta,
            liquidacion: updateProductoDto.liquidacion,
            fechaActualizacion: now
          })
          .where(
            and(
              eq(detallesProductoTable.sucursalId, sucursalId),
              eq(detallesProductoTable.productoId, numericIdDto.id)
            )
          )
          .returning({ id: detallesProductoTable.id })

        if (updatedDetallesProducto.length < 1 && updatedProductos.length < 1) {
          throw CustomError.badRequest(
            'Ha ocurrido un error al intentar actualizar el producto'
          )
        }
      })

      return numericIdDto
    } catch (error) {
      throw CustomError.badRequest(
        'Ha ocurrido un error al intentar actualizar el producto'
      )
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
        throw CustomError.badRequest(
          'La imagen es demasiado grande, la imagen puede tener como máximo 2400 píxeles de ancho y 2400 píxeles de alto'
        )
      }

      const uuid = crypto.randomUUID()
      const name = `${uuid}.webp`

      const basePath =
        this.photosDirectory != null
          ? path.join(this.publicStoragePath, this.photosDirectory)
          : this.publicStoragePath

      const filepath = path.join(basePath, name)

      await sharp(file.buffer)
        .resize(800, 800)
        .toFormat('webp')
        .webp({ quality: 80 })
        .toFile(filepath)

      return this.photosDirectory != null
        ? path.join(this.photosDirectory, name)
        : '/' + name
    } catch (error) {
      if (error instanceof CustomError) {
        throw error
      }

      throw CustomError.internalServer()
    }
  }

  private validatePermissions(sucursalId: SucursalIdType) {
    let hasPermissionAny = false
    let hasPermissionRelated = false
    let isSameSucursal = false

    for (const permission of this.permissions) {
      if (permission.codigoPermiso === this.permissionAny) {
        hasPermissionAny = true
      }
      if (permission.codigoPermiso === this.permissionRelated) {
        hasPermissionRelated = true
      }
      if (permission.sucursalId === sucursalId) {
        isSameSucursal = true
      }

      if (hasPermissionAny || (hasPermissionRelated && isSameSucursal)) {
        return
      }
    }

    throw CustomError.forbidden()
  }

  async execute(
    numericIdDto: NumericIdDto,
    updateProductoDto: UpdateProductoDto,
    sucursalId: SucursalIdType,
    file: Express.Multer.File | undefined
  ) {
    this.validatePermissions(sucursalId)

    const producto = await this.updateProducto(
      numericIdDto,
      updateProductoDto,
      sucursalId,
      file
    )

    return producto
  }
}
