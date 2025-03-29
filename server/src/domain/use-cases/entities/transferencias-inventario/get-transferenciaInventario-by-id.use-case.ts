import { db } from '@/db/connection'
import {
  estadosTransferenciasInventarios,
  itemsTransferenciaInventarioTable,
  productosTable,
  sucursalesTable,
  transferenciasInventariosTable
} from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { aliasedTable, eq } from 'drizzle-orm'

export class GetTransferenciasInventariosById {
  private readonly sucursalOrigen = aliasedTable(
    sucursalesTable,
    'sucursalOrigen'
  )
  private readonly sucursalDestino = aliasedTable(
    sucursalesTable,
    'sucursalDestino'
  )
  private readonly selectFields = {
    estado: estadosTransferenciasInventarios.nombre,
    nombreSucursalOrigen: this.sucursalOrigen.nombre,
    nombreSucursalDestino: this.sucursalDestino.nombre,
    modificable: transferenciasInventariosTable.modificable,
    salidaOrigen: transferenciasInventariosTable.salidaOrigen,
    llegadaDestino: transferenciasInventariosTable.llegadaDestino
  }
  private readonly selectFieldsItems = {
    id: itemsTransferenciaInventarioTable.id,
    cantidad: itemsTransferenciaInventarioTable.cantidad,
    nombreProducto: productosTable.nombre
  }

  private async getTransferenciaInventario(numericIdDto: NumericIdDto) {
    const transVenta = await db
      .select(this.selectFields)
      .from(transferenciasInventariosTable)
      .leftJoin(
        this.sucursalOrigen,
        eq(
          this.sucursalOrigen.id,
          transferenciasInventariosTable.sucursalOrigenId
        )
      )
      .leftJoin(
        this.sucursalDestino,
        eq(
          this.sucursalDestino.id,
          transferenciasInventariosTable.sucursalDestinoId
        )
      )
      .leftJoin(
        estadosTransferenciasInventarios,
        eq(
          estadosTransferenciasInventarios.id,
          transferenciasInventariosTable.estadoTransferenciaId
        )
      )
      .where(eq(transferenciasInventariosTable.id, numericIdDto.id))

    const itemsVenta = await db
      .select(this.selectFieldsItems)
      .from(itemsTransferenciaInventarioTable)
      .innerJoin(
        productosTable,
        eq(itemsTransferenciaInventarioTable.productoId, productosTable.id)
      )
      .where(
        eq(
          itemsTransferenciaInventarioTable.transferenciaInventarioId,
          numericIdDto.id
        )
      )

    const [transfventa] = transVenta

    return {
      ...transfventa,
      itemsVenta
    }
  }

  async execute(numericIdDto: NumericIdDto) {
    const transferenciaInventario =
      await this.getTransferenciaInventario(numericIdDto)
    return transferenciaInventario
  }
}
