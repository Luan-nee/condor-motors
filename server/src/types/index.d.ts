declare namespace Express {
  export interface Request {
    authPayload?: AuthPayload
    sucursalId?: number
  }
}

interface AuthPayload {
  id: number
}

interface DocumentoFacturacion {
  tipo_documento: string
  serie: string
  numero: string
  tipo_operacion: string
  fecha_de_emision: string
  hora_de_emision: string
  moneda: string
  porcentaje_de_venta: number
  fecha_de_vencimiento: string
  enviar_automaticamente_al_cliente: boolean
  datos_del_emisor: DatosDelEmisor
  cliente: Cliente
  totales: Totales
  items: Item[]
  acciones: Acciones
  termino_de_pago: TerminoDePago
  metodo_de_pago: string
  canal_de_venta: string
  orden_de_compra: string
  almacen: string
  observaciones: string
}

interface Acciones {
  formato_pdf: string
}

interface Cliente {
  cliente_tipo_documento: string
  cliente_numero_documento: string
  cliente_denominacion: string
  codigo_pais: string
  ubigeo: string
  cliente_direccion: string
  cliente_email: string
  cliente_telefono: string
}

interface DatosDelEmisor {
  codigo_establecimiento: string
}

interface Item {
  unidad: string
  codigo?: string
  descripcion: string
  codigo_producto_sunat: string
  codigo_producto_gsl: string
  cantidad: number
  valor_unitario: number
  precio_unitario: number
  tipo_tax: string
  total_base_tax: number
  total_tax: number
  total: number
}

interface TerminoDePago {
  descripcion: string
  tipo: string
}

interface Totales {
  total_exportacion: number
  total_gravadas: number
  total_inafectas: number
  total_exoneradas: number
  total_gratuitas: number
  total_tax: number
  total_venta: number
}
