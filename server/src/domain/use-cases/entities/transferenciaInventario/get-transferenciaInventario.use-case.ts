import { CustomError } from '@/core/errors/custom.error'
import {
  estadosTransferenciasInventarios,
  itemsTransferenciaInventarioTable,
  productosTable,
  sucursalesTable,
  transferenciasInventariosTable
} from '@/db/schema'
import type { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'

export class GetTransferenciasInventariosById {
  private readonly selectFields = {
    estado: estadosTransferenciasInventarios.nombre,
    nombreSucursalOrigen: sucursalesTable.nombre,
    nombreSucursalDestino: sucursalesTable.nombre,
    modificable: transferenciasInventariosTable.modificable,
    salidaOrigen: transferenciasInventariosTable.salidaOrigen,
    llegadaDestino: transferenciasInventariosTable.llegadaDestino,
    cantidad: itemsTransferenciaInventarioTable.cantidad,
    nombreProducto: productosTable.nombre
  }

  private async getTransferenciaInventario(numericIdDto: NumericIdDto) {
    // const transventas = await
    CustomError.badRequest({ dato: numericIdDto.id })
  }
}
