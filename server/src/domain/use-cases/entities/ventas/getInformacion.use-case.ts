import { db } from '@/db/connection'
import {
  tiposDocFacturacionTable,
  tiposDocumentoClienteTable,
  tiposTaxTable
} from '@/db/schema'

export class GetInformacion {
  public readonly taxDatos = {
    nombre: tiposTaxTable.nombre,
    codigoSunat: tiposTaxTable.codigoSunat,
    porcentaje: tiposTaxTable.porcentaje,
    codigo: tiposTaxTable.codigo
  }
  public readonly docFacturacion = {
    nombre: tiposDocFacturacionTable.nombre,
    codigoSunat: tiposDocFacturacionTable.codigoSunat,
    codigo: tiposDocFacturacionTable.codigo
  }
  public readonly docCliente = {
    nombre: tiposDocumentoClienteTable.nombre,
    codigoSunat: tiposDocumentoClienteTable.codigoSunat
  }

  private async getInformacion() {
    const tiposTax = await db.select(this.taxDatos).from(tiposTaxTable)
    const tiposDocFacturacion = await db
      .select(this.docFacturacion)
      .from(tiposDocFacturacionTable)
    const clitiposDocCliententeDoc = await db
      .select(this.docCliente)
      .from(tiposDocumentoClienteTable)

    const [tiposTaxs] = tiposTax

    return { tiposTaxs, tiposDocFacturacion, clitiposDocCliententeDoc }
  }

  async execute() {
    const datos = await this.getInformacion()
    return datos
  }
}
