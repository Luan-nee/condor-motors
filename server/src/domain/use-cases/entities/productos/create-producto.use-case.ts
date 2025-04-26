import { permissionCodes } from '@/consts'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import {
  categoriasTable,
  coloresTable,
  detallesProductoTable,
  marcasTable,
  productosTable,
  sucursalesTable
} from '@/db/schema'
import type { CreateProductoDto } from '@/domain/dtos/entities/productos/create-producto.dto'
import type { SucursalIdType } from '@/types/schemas'
import { eq } from 'drizzle-orm'
import path from 'node:path'
import sharp from 'sharp'

export class CreateProducto {
  private readonly permissionAny = permissionCodes.productos.createAny
  private readonly permissionRelated = permissionCodes.productos.createRelated

  constructor(
    // private readonly authPayload: AuthPayload,
    private readonly permissions: Permission[],
    private readonly publicStoragePath: string,
    private readonly photosDirectory?: string
  ) {}

  private async createProducto(
    createProductoDto: CreateProductoDto,
    sucursalId: SucursalIdType,
    file: Express.Multer.File | undefined
  ) {
    const mappedPrices = {
      precioCompra: createProductoDto.precioCompra.toFixed(2),
      precioVenta: createProductoDto.precioVenta.toFixed(2),
      precioOferta: createProductoDto.precioOferta?.toFixed(2)
    }

    const detalleProductoStockBajo =
      createProductoDto.stockMinimo != null &&
      createProductoDto.stock < createProductoDto.stockMinimo

    const pathFoto = file !== undefined ? await this.saveFoto(file) : undefined

    const insertedProductResult = await db.transaction(async (tx) => {
      const [producto] = await tx
        .insert(productosTable)
        .values({
          nombre: createProductoDto.nombre,
          descripcion: createProductoDto.descripcion,
          maxDiasSinReabastecer: createProductoDto.maxDiasSinReabastecer,
          stockMinimo: createProductoDto.stockMinimo,
          cantidadMinimaDescuento: createProductoDto.cantidadMinimaDescuento,
          cantidadGratisDescuento: createProductoDto.cantidadGratisDescuento,
          porcentajeDescuento: createProductoDto.porcentajeDescuento,
          pathFoto,
          colorId: createProductoDto.colorId,
          categoriaId: createProductoDto.categoriaId,
          marcaId: createProductoDto.marcaId
        })
        .returning({
          id: productosTable.id
        })

      await tx
        .insert(detallesProductoTable)
        .values({
          precioCompra: mappedPrices.precioCompra,
          precioVenta: mappedPrices.precioVenta,
          precioOferta: mappedPrices.precioOferta,
          stock: createProductoDto.stock,
          stockBajo: detalleProductoStockBajo,
          productoId: producto.id,
          liquidacion: createProductoDto.liquidacion,
          sucursalId
        })
        .returning({
          id: detallesProductoTable.id
        })

      return producto
    })

    return insertedProductResult
  }

  private async validateRelacionados(
    createProductoDto: CreateProductoDto,
    sucursalId: SucursalIdType
  ) {
    const results = await db
      .select({
        sucursalId: sucursalesTable.id,
        color: coloresTable.nombre,
        categoria: categoriasTable.nombre,
        marca: marcasTable.nombre
      })
      .from(sucursalesTable)
      .leftJoin(coloresTable, eq(coloresTable.id, createProductoDto.colorId))
      .leftJoin(
        categoriasTable,
        eq(categoriasTable.id, createProductoDto.categoriaId)
      )
      .leftJoin(marcasTable, eq(marcasTable.id, createProductoDto.marcaId))
      .where(eq(sucursalesTable.id, sucursalId))

    if (results.length < 1) {
      throw CustomError.badRequest('La sucursal que intentó asignar no existe')
    }

    const [result] = results

    if (result.color === null) {
      throw CustomError.badRequest('El color que intentó asignar no existe')
    }

    if (result.categoria === null) {
      throw CustomError.badRequest('La categoría que intentó asignar no existe')
    }

    if (result.marca === null) {
      throw CustomError.badRequest('La marca que intentó asignar no existe')
    }

    // return {
    //   color: result.color,
    //   categoria: result.categoria,
    //   marca: result.marca
    // }
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
    createProductoDto: CreateProductoDto,
    sucursalId: SucursalIdType,
    file: Express.Multer.File | undefined
  ) {
    this.validatePermissions(sucursalId)

    await this.validateRelacionados(createProductoDto, sucursalId)

    const producto = await this.createProducto(
      createProductoDto,
      sucursalId,
      file
    )

    return producto
  }
}
