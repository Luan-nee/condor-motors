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
  private readonly selectFields = {
    id: transferenciasInventariosTable.id,
    estado: {
      nombre: estadosTransferenciasInventarios.nombre,
      codigo: estadosTransferenciasInventarios.codigo
    },
    sucursalOrigen: {
      id: this.sucursalOrigen.id,
      nombre: this.sucursalOrigen.nombre
    },
    sucursalDestino: {
      id: sucursalesTable.id,
      nombre: sucursalesTable.nombre
    },
    modificable: transferenciasInventariosTable.modificable,
    salidaOrigen: transferenciasInventariosTable.salidaOrigen,
    llegadaDestino: transferenciasInventariosTable.llegadaDestino
  }
  private readonly selectFieldsItems = {
    id: itemsTransferenciaInventarioTable.id,
    cantidad: itemsTransferenciaInventarioTable.cantidad,
    nombre: productosTable.nombre,
    productoId: productosTable.id
  }

  private async getTransferenciaInventario(numericIdDto: NumericIdDto) {
    const [transferenciaInventario] = await db
      .select(this.selectFields)
      .from(transferenciasInventariosTable)
      .leftJoin(
        sucursalesTable,
        eq(transferenciasInventariosTable.sucursalDestinoId, sucursalesTable.id)
      )
      .leftJoin(
        this.sucursalOrigen,
        eq(
          this.sucursalOrigen.id,
          transferenciasInventariosTable.sucursalOrigenId
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

    const items = await db
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

    return {
      ...transferenciaInventario,
      items
    }
  }

  async execute(numericIdDto: NumericIdDto) {
    const transferenciaInventario =
      await this.getTransferenciaInventario(numericIdDto)
    return transferenciaInventario
  }
}
