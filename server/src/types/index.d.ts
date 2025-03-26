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
  datos_del_emisor: {
    codigo_establecimiento: string
  }
  cliente: {
    cliente_tipo_documento: string
    cliente_numero_documento: string
    cliente_denominacion: string
    codigo_pais: string
    ubigeo: string
    cliente_direccion: string
    cliente_email: string
    cliente_telefono: string
  }
  totales: {
    total_exportacion: number
    total_gravadas: number
    total_inafectas: number
    total_exoneradas: number
    total_gratuitas: number
    total_tax: number
    total_venta: number
  }
  items: Item[]
  acciones: {
    formato_pdf: string
  }
  termino_de_pago: {
    descripcion: string
    tipo: string
  }
  metodo_de_pago: string
  canal_de_venta: string
  orden_de_compra: string
  almacen: string
  observaciones: string
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

interface BillingApiSuccessResponse {
  success: boolean
  message: string
  data: {
    number: string
    filename: string
    external_id: string
    number_to_letter: string
    hash: string
    qr: string
    state_type_id: string
    state_description: string
  }
  links: {
    xml: string
    cdr: string
    pdf: string
    download_pdf: string
    pdf_html: string
  }
  sunat_information: {
    code: string
    description: string
    notes: any[]
  }
}

interface BillingApiErrorResponse {
  success: boolean
  message: string
}

interface ConsultDocument {
  tipo_documento: string
  serie: string
  numero: string
}
