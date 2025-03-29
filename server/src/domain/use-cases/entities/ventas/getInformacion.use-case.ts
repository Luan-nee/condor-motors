import { db } from '@/db/connection'
import {
  tiposDocFacturacionTable,
  tiposDocumentoClienteTable,
  tiposTaxTable
} from '@/db/schema'

export class GetInformacion {
  public readonly taxDatos = {
    id: tiposTaxTable.id,
    nombre: tiposTaxTable.nombre,
    codigo: tiposTaxTable.codigo
  }
  public readonly docFacturacion = {
    id: tiposDocFacturacionTable.id,
    nombre: tiposDocFacturacionTable.nombre,
    codigo: tiposDocFacturacionTable.codigo
  }
  public readonly docCliente = {
    id: tiposDocumentoClienteTable.id,
    nombre: tiposDocumentoClienteTable.nombre
  }

  private async getInformacion() {
    const tiposTax = await db.select(this.taxDatos).from(tiposTaxTable)

    const tiposDocFacturacion = await db
      .select(this.docFacturacion)
      .from(tiposDocFacturacionTable)

    const tiposDocCliente = await db
      .select(this.docCliente)
      .from(tiposDocumentoClienteTable)

    return { tiposTax, tiposDocFacturacion, tiposDocCliente }
  }

  async execute() {
    const datos = await this.getInformacion()
    return datos
  }
}
