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
    const taxDatosvalores = await db.select(this.taxDatos).from(tiposTaxTable)
    const facturacion = await db
      .select(this.docFacturacion)
      .from(tiposDocFacturacionTable)
    const clienteDoc = await db
      .select(this.docCliente)
      .from(tiposDocumentoClienteTable)

    const [valores] = taxDatosvalores

    return { ...valores, facturacion, clienteDoc }
  }

  async execute() {
    const datos = await this.getInformacion()
    return datos
  }
}
