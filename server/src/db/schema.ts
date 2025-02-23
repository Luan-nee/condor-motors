import {
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

export const unidadesTable = pgTable('unidades', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique()
})

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

export const sucursalesTable = pgTable('sucursales', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  direccion: text('direccion'),
  sucursalCentral: boolean('sucursal_central').notNull(),
  fechaRegistro: timestamp('fecha_registro', {
    mode: 'date'
  })
    .notNull()
    .defaultNow()
})

export const notificacionesTable = pgTable('notificaciones', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  titulo: text('titulo').notNull(),
  descripcion: text('descripcion'),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id)
})

export const productosTable = pgTable('productos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  sku: text('sku').notNull().unique(),
  nombre: text('nombre').notNull().unique(),
  descripcion: text('descripcion'),
  maxDiasSinReabastecer: integer('max_dias_sin_reabastecer').default(30),
  unidadId: integer('unidad_id')
    .notNull()
    .references(() => unidadesTable.id),
  categoriaId: integer('categoria_id')
    .notNull()
    .references(() => unidadesTable.id),
  marcaId: integer('marca_id')
    .notNull()
    .references(() => unidadesTable.id)
})

// Se requiere esta tabla?
export const gruposProductosTable = pgTable('grupos_productos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  cantidadGrupo: integer('cantidad_grupo').notNull().default(2),
  productoId: integer('producto_id')
    .notNull()
    .references(() => productosTable.id)
})

export const fotosProductosTable = pgTable('fotos_productos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  ubicacion: text('ubicacion').notNull(),
  productoId: integer('producto_id').references(() => productosTable.id),
  grupoProductoId: integer('grupo_producto_id').references(
    () => gruposProductosTable.id
  )
})

export const preciosProductosTable = pgTable('precios_productos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  precioBase: numeric('precio_base', { precision: 7, scale: 2 }),
  precioMayorista: numeric('precio_mayorista', { precision: 7, scale: 2 }),
  precioOferta: numeric('precio_oferta', { precision: 7, scale: 2 }),
  productoId: integer('producto_id').references(() => productosTable.id),
  grupoProductoId: integer('grupo_producto_id').references(
    () => gruposProductosTable.id
  ),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id)
})

export const inventariosTable = pgTable('inventarios', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  stock: integer('stock').notNull().default(0),
  fechaStockReabastecido: timestamp('fecha_stock_reabastecido', {
    mode: 'date'
  })
    .notNull()
    .defaultNow(),
  productoId: integer('producto_id')
    .notNull()
    .references(() => productosTable.id),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id)
})

export const empleadosTable = pgTable('empleados', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull(),
  apellidos: text('apellidos').notNull(),
  ubicacionFoto: text('ubicacion_foto'),
  edad: integer('edad'),
  dni: text('dni'),
  horaInicioJornada: time('hora_inicio_jornada'),
  horaFinJornada: time('hora_fin_jornada'),
  fechaContratacion: date('', {
    mode: 'date'
  }),
  sueldo: numeric('sueldo', {
    precision: 7,
    scale: 2
  }),
  fechaRegistro: timestamp('fecha_registro', {
    mode: 'date'
  })
    .notNull()
    .defaultNow(),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id)
})

export const tiposPersonasTable = pgTable('tipos_personas', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique()
})

export const clientesTable = pgTable('clientes', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombresApellidos: text('nombres_apellidos'),
  dni: text('dni'),
  razonSocial: text('razon_social'),
  ruc: text('ruc'),
  telefono: text(''),
  correo: text(''),
  fechaRegistro: timestamp('fecha_registro', {
    mode: 'date'
  })
    .notNull()
    .defaultNow(),
  tipoPersonaId: integer('tipo_persona_id')
    .notNull()
    .references(() => tiposPersonasTable.id)
})

export const rolesCuentasEmpleadosTable = pgTable('roles_cuentas_empleados', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombreRol: text('nombre_rol').notNull().unique()
})

export const cuentasEmpleadosTable = pgTable('cuentas_empleados', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  usuario: text('usuario').notNull().unique(),
  clave: text('clave').notNull(),
  secret: text('secret').notNull(),
  fechaRegistro: timestamp('fecha_registro', {
    mode: 'date'
  })
    .notNull()
    .defaultNow(),
  rolCuentaEmpleadoId: integer('rol_cuenta_empleado_id')
    .notNull()
    .references(() => rolesCuentasEmpleadosTable.id),
  empleadoId: integer('empleado_id')
    .notNull()
    .references(() => empleadosTable.id)
})

export const permisosTables = pgTable('permisos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombrePermiso: text('nombre_permiso').notNull().unique()
})

export const rolesPermisosTable = pgTable(
  'roles_permisos',
  {
    rolId: integer('rol_id')
      .notNull()
      .references(() => rolesCuentasEmpleadosTable.id),
    permisoId: integer('permiso_id')
      .notNull()
      .references(() => permisosTables.id)
  },
  (table) => [primaryKey({ columns: [table.rolId, table.permisoId] })]
)

export const proformasVentaTable = pgTable('proformas_venta', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre'),
  fechaCreacion: timestamp('fecha_creacion', {
    mode: 'date'
  })
    .notNull()
    .defaultNow(),
  detalles: jsonb('detalles').notNull().$type<
    Array<{
      productoId: number
      grupoProductoId: number
      cantidad: number
      subtotal: number
    }>
  >(),
  empleadoId: integer('empleado_id')
    .notNull()
    .references(() => empleadosTable.id),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id)
})

export const metodosPagoTable = pgTable('metodos_pago', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  codigo: text('codigo').notNull().unique(),
  activado: boolean('activado').notNull()
})

export const ventasTable = pgTable('ventas', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  total: numeric('total', { precision: 8, scale: 2 }).notNull(),
  fechaCreacion: timestamp('fecha_creacion', {
    mode: 'date'
  })
    .notNull()
    .defaultNow(),
  observaciones: text('observaciones'),
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
    .references(() => sucursalesTable.id)
})

export const detallesTable = pgTable('detalles', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  cantidad: integer('cantidad').notNull().default(1),
  subtotal: numeric('subtotal', { precision: 7, scale: 2 }).notNull(),
  productoId: integer('producto_id').references(() => productosTable.id),
  grupoProductoId: integer('grupo_producto_id').references(
    () => gruposProductosTable.id
  ),
  ventaId: integer('venta_id')
    .notNull()
    .references(() => ventasTable.id)
})

export const descuentosTable = pgTable('descuentos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  monto: numeric('monto', { precision: 7, scale: 2 }).notNull(),
  descripcion: text('descripcion'),
  ventaId: integer('venta_id')
    .notNull()
    .references(() => ventasTable.id)
})

export const devolucionesTable = pgTable('devoluciones', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  motivo: text('motivo').notNull(),
  fechaDevolucion: timestamp('fecha_devolucion', {
    mode: 'date'
  })
    .notNull()
    .defaultNow(),
  ventaId: integer('venta_id')
    .notNull()
    .references(() => ventasTable.id),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id)
})

export const entradasInventariosTable = pgTable('entradas_inventarios', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  cantidad: integer('cantidad').notNull().default(1),
  fechaMovimiento: timestamp('fecha_movimiento', {
    mode: 'date'
  })
    .notNull()
    .defaultNow(),
  productoId: integer('producto_id')
    .notNull()
    .references(() => productosTable.id),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id)
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
    cantidad: integer('cantidad').notNull().default(1),
    fechaTransferencia: timestamp('fecha_transferencia', {
      mode: 'date'
    })
      .notNull()
      .defaultNow(),
    estadoTransferenciaId: integer('estado_transferencia_id')
      .notNull()
      .references(() => estadosTransferenciasInventarios.id),
    productoId: integer('producto_id')
      .notNull()
      .references(() => productosTable.id),
    sucursalOrigenId: integer('sucursal_origen_id')
      .notNull()
      .references(() => sucursalesTable.id),
    sucursalDestinoId: integer('sucursal_destino_id')
      .notNull()
      .references(() => sucursalesTable.id)
  }
)

export const reservasProductosTable = pgTable('reservas_productos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  cantidad: integer('cantidad').notNull().default(1),
  total: numeric('total', { precision: 7, scale: 2 }).notNull(),
  montoAdelantado: numeric('monto_adelantado', {
    precision: 7,
    scale: 2
  }).notNull(),
  fechaReserva: timestamp('fecha_reserva', {
    mode: 'date'
  })
    .notNull()
    .defaultNow(),
  clienteId: integer('cliente_id')
    .notNull()
    .references(() => clientesTable.id),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id)
})
