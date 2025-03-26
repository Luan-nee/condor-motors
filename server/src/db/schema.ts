/* eslint-disable max-lines */
import { sql } from 'drizzle-orm'
import {
  uniqueIndex,
  index,
  boolean,
  date,
  integer,
  jsonb,
  numeric,
  pgTable,
  primaryKey,
  text,
  time,
  timestamp
} from 'drizzle-orm/pg-core'

const timestampsColumns = {
  fechaCreacion: timestamp('fecha_creacion', {
    mode: 'date',
    withTimezone: false
  })
    .notNull()
    .defaultNow(),
  fechaActualizacion: timestamp('fecha_actualizacion', {
    mode: 'date',
    withTimezone: false
  })
    .notNull()
    .defaultNow()
}

export const sucursalesTable = pgTable('sucursales', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  direccion: text('direccion'),
  sucursalCentral: boolean('sucursal_central').notNull(),
  serieFacturaSucursal: text('serie_factura_sucursal').unique(),
  numeroFacturaInicial: integer('numero_factura_inicial').default(1),
  serieBoletaSucursal: text('serie_boleta_sucursal').unique(),
  numeroBoletaInicial: integer('numero_boleta_inicial').default(1),
  codigoEstablecimiento: text('codigo_establecimiento').unique(),
  tieneNotificaciones: boolean('tiene_notificaciones').notNull().default(false),
  ...timestampsColumns
})

/*
 * Productos
 */

export const categoriasTable = pgTable('categorias', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  descripcion: text('descripcion')
})

export const marcasTable = pgTable('marcas', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  descripcion: text('descripcion')
})

export const coloresTable = pgTable('colores', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  hex: text('hex')
})

export const productosTable = pgTable(
  'productos',
  {
    id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
    sku: text('sku')
      .notNull()
      .unique()
      .generatedAlwaysAs(sql`LPAD(id::TEXT, 7, '0')`),
    nombre: text('nombre').notNull(),
    descripcion: text('descripcion'),
    maxDiasSinReabastecer: integer('max_dias_sin_reabastecer'),
    stockMinimo: integer('stock_minimo'),
    cantidadMinimaDescuento: integer('cantidad_minima_descuento'),
    cantidadGratisDescuento: integer('cantidad_gratis_descuento'),
    porcentajeDescuento: integer('porcentaje_descuento'),
    colorId: integer('color_id')
      .notNull()
      .references(() => coloresTable.id),
    categoriaId: integer('categoria_id')
      .notNull()
      .references(() => categoriasTable.id),
    marcaId: integer('marca_id')
      .notNull()
      .references(() => marcasTable.id),
    ...timestampsColumns
  },
  (table) => [
    index('productos_nombre_idx').on(table.nombre),
    uniqueIndex('productos_sku_idx').on(table.sku),
    index('productos_fecha_creacion_idx').on(table.fechaCreacion),
    index('productos_color_id_idx').on(table.colorId),
    index('productos_categoria_id_idx').on(table.categoriaId),
    index('productos_marca_id_idx').on(table.marcaId)
  ]
)

export const detallesProductoTable = pgTable(
  'detalles_producto',
  {
    id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
    precioCompra: numeric('precio_compra', {
      precision: 7,
      scale: 2
    }).notNull(),
    porcentajeGanancia: text('porcentaje_ganancia'),
    precioVenta: numeric('precio_venta', { precision: 7, scale: 2 }).notNull(),
    precioOferta: numeric('precio_oferta', { precision: 7, scale: 2 }),
    stock: integer('stock').notNull().default(0),
    stockBajo: boolean('stock_bajo').notNull().default(false),
    liquidacion: boolean('liquidacion').notNull().default(false),
    productoId: integer('producto_id')
      .notNull()
      .references(() => productosTable.id),
    sucursalId: integer('sucursal_id')
      .notNull()
      .references(() => sucursalesTable.id),
    ...timestampsColumns
  },
  (table) => [
    index('detalles_producto_precio_compra_idx').on(table.precioCompra),
    index('detalles_producto_precio_venta_idx').on(table.precioVenta),
    index('detalles_producto_precio_oferta_idx').on(table.precioOferta),
    index('detalles_producto_precio_stock_idx').on(table.stock)
  ]
)

export const fotosProductoTable = pgTable('fotos_producto', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  path: text('path').notNull(),
  productoId: integer('producto_id')
    .notNull()
    .references(() => productosTable.id),
  ...timestampsColumns
})

/*
 * Empleados y clientes
 */

export const empleadosTable = pgTable('empleados', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull(),
  apellidos: text('apellidos').notNull(),
  activo: boolean('activo').notNull().default(true),
  dni: text('dni').notNull().unique(),
  pathFoto: text('path_foto'),
  celular: text('celular'),
  horaInicioJornada: time('hora_inicio_jornada'),
  horaFinJornada: time('hora_fin_jornada'),
  fechaContratacion: date('fecha_contratacion', {
    mode: 'string'
  }),
  sueldo: numeric('sueldo', {
    precision: 7,
    scale: 2
  }),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id),
  ...timestampsColumns
})

export const tiposDocumentoClienteTable = pgTable('tipos_documento_cliente', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  codigo: text('codigo').notNull().unique()
})

export const clientesTable = pgTable('clientes', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  tipoDocumentoId: integer('tipo_documento_id')
    .notNull()
    .references(() => tiposDocumentoClienteTable.id),
  numeroDocumento: text('numero_documento').notNull(),
  denominacion: text('denominacion').notNull(),
  codigoPais: text('codigo_pais').notNull().default('PE'),
  direccion: text('direccion'),
  correo: text('correo'),
  telefono: text('telefono'),
  ...timestampsColumns
})

/*
 * Inventarios
 */

export const entradasInventariosTable = pgTable('entradas_inventarios', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  cantidad: integer('cantidad').notNull().default(1),
  productoId: integer('producto_id')
    .notNull()
    .references(() => productosTable.id),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id),
  ...timestampsColumns
})

export const estadosTransferenciasInventarios = pgTable(
  'estados_transferencias_inventarios',
  {
    id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
    nombre: text('nombre').notNull().unique(),
    codigo: text('codigo').notNull().unique()
  }
)

export const transferenciasInventariosTable = pgTable(
  'transferencias_inventarios',
  {
    id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
    solicitanteId: integer('empleado_id')
      .notNull()
      .references(() => empleadosTable.id),
    proveedorId: integer('proveedor_id')
      .notNull()
      .references(() => empleadosTable.id),
    estadoTransferenciaId: integer('estado_transferencia_id')
      .notNull()
      .references(() => estadosTransferenciasInventarios.id),
    sucursalOrigenId: integer('sucursal_origen_id')
      .notNull()
      .references(() => sucursalesTable.id),
    sucursalDestinoId: integer('sucursal_destino_id')
      .notNull()
      .references(() => sucursalesTable.id),
    salidaOrigen: timestamp('salida_origen', {
      mode: 'date',
      withTimezone: false
    })
      .notNull()
      .defaultNow(),
    llegadaDestino: timestamp('llegada_destino', {
      mode: 'date',
      withTimezone: false
    }),
    ...timestampsColumns
  }
)

export const detallesTransferenciaInventarioTable = pgTable(
  'detalles_transferencia_inventario',
  {
    id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
    cantidad: integer('cantidad').notNull().default(1),
    productoId: integer('producto_id')
      .notNull()
      .references(() => productosTable.id),
    transferenciaInventarioId: integer('transferencia_inventario_id')
      .notNull()
      .references(() => transferenciasInventariosTable.id)
  }
)

/*
 * Usuarios
 */

export const permisosTable = pgTable('permisos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  codigoPermiso: text('codigo_permiso').notNull().unique(),
  nombrePermiso: text('nombre_permiso').notNull().unique()
})

export const rolesCuentasEmpleadosTable = pgTable('roles_cuentas_empleados', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  codigo: text('codigo').notNull().unique(),
  nombreRol: text('nombre_rol').notNull().unique()
})

export const cuentasEmpleadosTable = pgTable('cuentas_empleados', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  usuario: text('usuario').notNull().unique(),
  clave: text('clave').notNull(),
  secret: text('secret').notNull(),
  rolCuentaEmpleadoId: integer('rol_cuenta_empleado_id')
    .notNull()
    .references(() => rolesCuentasEmpleadosTable.id),
  empleadoId: integer('empleado_id')
    .notNull()
    .references(() => empleadosTable.id),
  ...timestampsColumns
})

export const rolesPermisosTable = pgTable(
  'roles_permisos',
  {
    rolId: integer('rol_id')
      .notNull()
      .references(() => rolesCuentasEmpleadosTable.id),
    permisoId: integer('permiso_id')
      .notNull()
      .references(() => permisosTable.id)
  },
  (table) => [primaryKey({ columns: [table.rolId, table.permisoId] })]
)

/*
 * Ventas
 */

export const tiposDocumentoFacturacionTable = pgTable(
  'tipos_documento_facturacion',
  {
    id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
    nombre: text('nombre').notNull().unique(),
    codigo: text('codigo').notNull().unique(),
    codigoLocal: text('codigo_local').notNull()
  }
)

export const monedasFacturacionTable = pgTable('monedas_facturacion', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  codigo: text('codigo').notNull().unique()
})

export const metodosPagoTable = pgTable('metodos_pago', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  codigo: text('codigo').notNull().unique(),
  tipo: text('tipo').notNull().unique(),
  activado: boolean('activado').notNull()
})

export const ventasTable = pgTable('ventas', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  observaciones: text('observaciones'),
  tipoOperacion: text('tipo_operacion').notNull().default('0101'),
  porcentajeVenta: integer('porcentaje_venta').notNull().default(18),
  tipoDocumentoId: integer('tipo_documento_id')
    .notNull()
    .references(() => tiposDocumentoFacturacionTable.id),
  serieDocumento: text('serie_documento').notNull(),
  numeroDocumento: text('numero_documento').notNull(),
  monedaId: integer('moneda_id')
    .notNull()
    .references(() => monedasFacturacionTable.id),
  metodoPagoId: integer('metodo_pago_id')
    .notNull()
    .references(() => metodosPagoTable.id),
  clienteId: integer('cliente_id')
    .notNull()
    .references(() => clientesTable.id),
  empleadoId: integer('empleado_id')
    .notNull()
    .references(() => empleadosTable.id),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id),
  fechaEmision: date('fecha_emision', {
    mode: 'string'
  }).notNull(),
  horaEmision: time('hora_emision').notNull(),
  declarada: boolean('declarada').notNull().default(false),
  ...timestampsColumns
})

export const tiposTaxTable = pgTable('tipos_tax', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  codigo: text('codigo').notNull().unique(),
  porcentajeTax: integer('porcentaje').notNull(),
  codigoLocal: text('codigo_local').notNull()
})

export const detallesVentaTable = pgTable('detalles_venta', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  tipoUnidad: text('tipo_unidad').notNull().default('NIU'),
  sku: text('sku').notNull(),
  nombre: text('nombre').notNull(),
  cantidad: integer('cantidad').notNull().default(1),
  precioSinIgv: numeric('precio_sin_igv', { precision: 7, scale: 2 }).notNull(),
  precioConIgv: numeric('precio_con_igv', { precision: 7, scale: 2 }).notNull(),
  tipoTaxId: integer('tipo_tax_id')
    .notNull()
    .references(() => tiposTaxTable.id),
  totalBaseTax: numeric('total_base_tax', { precision: 7, scale: 2 }).notNull(),
  totalTax: numeric('total_tax', { precision: 7, scale: 2 }).notNull(),
  total: numeric('total', { precision: 7, scale: 2 }).notNull(),
  ventaId: integer('venta_id')
    .notNull()
    .references(() => ventasTable.id)
})

export const totalesVentaTable = pgTable('totales_venta', {
  totalGravadas: numeric('total_gravadas', {
    precision: 7,
    scale: 2
  }).notNull(),
  totalExoneradas: numeric('total_exoneradas', {
    precision: 7,
    scale: 2
  }).notNull(),
  totalGratuitas: numeric('total_gratuitas', {
    precision: 7,
    scale: 2
  }).notNull(),
  totalTax: numeric('total_tax', {
    precision: 7,
    scale: 2
  }).notNull(),
  totalVenta: numeric('total_venta', {
    precision: 7,
    scale: 2
  }).notNull(),
  ventaId: integer('venta_id')
    .notNull()
    .references(() => ventasTable.id)
})

/*
 * Extra ventas
 */

export const proformasVentaTable = pgTable('proformas_venta', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre'),
  total: numeric('total', { precision: 8, scale: 2 }).notNull(),
  detalles: jsonb('detalles').notNull().$type<
    Array<{
      productoId: number
      nombre: string
      precioUnitario: number
      precioOriginal: number
      cantidadGratis: number | null
      descuento: number | null
      cantidadPagada: number
      cantidadTotal: number
      subtotal: number
    }>
  >(),
  empleadoId: integer('empleado_id')
    .notNull()
    .references(() => empleadosTable.id),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id),
  ...timestampsColumns
})

export const reservasProductosTable = pgTable('reservas_productos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  descripcion: text('descripcion'),
  detallesReserva: jsonb('detalles_reserva').notNull().$type<{
    nombreProducto: string
    precioCompra: number
    precioVenta: number
    cantidad: number
    total: number
  }>(),
  montoAdelantado: numeric('monto_adelantado', {
    precision: 7,
    scale: 2
  }).notNull(),
  fechaRecojo: date('fecha_recojo', {
    mode: 'string'
  }),
  clienteId: integer('cliente_id')
    .notNull()
    .references(() => clientesTable.id),
  sucursalId: integer('sucursal_id').references(() => sucursalesTable.id),
  ...timestampsColumns
})

export const devolucionesTable = pgTable('devoluciones', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  motivo: text('motivo').notNull(),
  ventaId: integer('venta_id')
    .notNull()
    .references(() => ventasTable.id),
  ...timestampsColumns
})

/*
 * Facturación
 */

export const estadosDocumentoFacturacion = pgTable(
  'estados_documento_facturacion',
  {
    id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
    nombre: text('nombre').notNull().unique(),
    codigo: text('codigo').notNull().unique(),
    codigoLocal: text('codigo_local').notNull()
  }
)

export const documentosFacturacionTable = pgTable('documentos_facturacion', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  factproFilename: text('factpro_filename'),
  factproDocumentId: text('factpro_document_id'),
  hash: text('hash'),
  qr: text('qr'),
  linkXml: text('link_xml'),
  linkPdf: text('link_pdf'),
  linkCdr: text('link_cdr'),
  estadoRawId: text('estado_raw_id'),
  informacionSunat: jsonb('informacion_sunat'),
  estadoId: integer('estado_id').references(
    () => estadosDocumentoFacturacion.id
  ),
  ventaId: integer('venta_id')
    .notNull()
    .references(() => ventasTable.id)
})

/*
 * Extras
 * */

export const notificacionesTable = pgTable('notificaciones', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  titulo: text('titulo').notNull(),
  descripcion: text('descripcion'),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id),
  ...timestampsColumns
})
