/* 
 * Este es solo un diseño temprano de la base de datos, no se recomienda ejecutar este script sql directamente en su equipo
 */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 * [Tablas]:
 * unidades
 * categorias
 * marcas
 * sucursales
 * notificaciones
 * productos
 * grupos_productos
 * fotos_productos
 * precios_productos
 * inventarios
 * empleados
 * tipos_personas
 * clientes
 * roles_cuentas_empleados
 * cuentas_empleados
 * permisos
 * roles_permisos
 * refresh_tokens_empleados
 * proformas_venta
 * metodos_pago
 * ventas
 * detalles
 * descuentos
 * devoluciones
 * entradas_inventarios
 * transferencias_inventarios
 * reservas_productos
 * facturas? boletas?
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
 * [Comentarios]:
 * Donde se guarda la configuración de la empresa emisora de la factura o boleta???
 * Se viene nueva tabla o eso está en el servicio de facturación?
 * El campo `max_dias_sin_reabastecer` de la tabla `productos`
 *    debería ser general o por cada sucursal?
 * `proformas_venta` debería ser una tabla con registros dinámicos
 *    que se crean y se eliminan constantemente
 * Las tablas `proformas_venta` y `ventas` poseen el campo "total" a la vez, 
 *    lo cual no tiene mucho sentido
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
-- drop database if exists condor_motors_db;
create database if not exists condor_motors_db;

use condor_motors_db;

create table if not exists
  unidades (
    id bigint auto_increment,
    nombre varchar(100) not null unique,
    primary key (id)
  );

create table if not exists
  categorias (
    id bigint auto_increment,
    nombre varchar(255) not null unique,
    descripcion varchar(511),
    primary key (id)
  );

create table if not exists
  marcas (
    id bigint auto_increment,
    nombre varchar(255) not null unique,
    descripcion varchar(511),
    primary key (id)
  );

create table if not exists
  sucursales (
    id bigint auto_increment,
    nombre varchar(255) not null unique,
    ubicacion varchar(511),
    sucursal_central boolean not null,
    fecha_registro timestamp not null default current_timestamp,
    primary key (id)
  );

create table if not exists
  notificaciones (
    id bigint auto_increment,
    titulo varchar(255) not null,
    descripcion varchar(1023),
    sucursal_id bigint not null,
    foreign key (sucursal_id) references sucursales (id),
    primary key (id)
  );

create table if not exists
  productos (
    id bigint auto_increment,
    sku varchar(255) not null unique,
    nombre varchar(255) not null unique,
    descripcion varchar(255) not null,
    -- Este campo debería ser general o por cada sucursal?
    max_dias_sin_reabastecer int default 30,
    unidad_id bigint not null,
    categoria_id bigint not null,
    marca_id bigint not null,
    foreign key (unidad_id) references unidades (id),
    foreign key (categoria_id) references categorias (id),
    foreign key (marca_id) references marcas (id),
    primary key (id)
  );

-- Se requiere esta tabla?
create table if not exists
  grupos_productos (
    id bigint auto_increment,
    nombre varchar(255) not null,
    cantidad_grupo int not null default 1,
    producto_id bigint not null,
    foreign key (producto_id) references productos (id),
    primary key (id)
  );

create table if not exists
  fotos_productos (
    id bigint auto_increment,
    ubicacion varchar(1023) not null,
    producto_id bigint,
    grupo_producto_id bigint,
    foreign key (producto_id) references productos (id),
    foreign key (grupo_producto_id) references grupos_productos (id),
    primary key (id)
  );

create table if not exists
  precios_productos (
    id bigint auto_increment,
    precio_normal decimal(7, 2) not null,
    precio_mayorista decimal(7, 2) not null,
    precio_oferta decimal(7, 2) not null,
    producto_id bigint not null,
    sucursal_id bigint not null,
    foreign key (producto_id) references productos (id),
    foreign key (sucursal_id) references sucursales (id),
    primary key (id)
  );

create table if not exists
  inventarios (
    id bigint auto_increment,
    stock bigint default 0 not null,
    fecha_stock_reabastecido timestamp not null default current_timestamp,
    producto_id bigint not null,
    sucursal_id bigint not null,
    foreign key (producto_id) references productos (id),
    foreign key (sucursal_id) references sucursales (id),
    primary key (id)
  );

create table if not exists
  empleados (
    id bigint auto_increment,
    nombre varchar(255) not null,
    apellidos varchar(255) not null,
    ubicacion_foto varchar(1023),
    edad tinyint,
    dni varchar(10),
    hora_inicio_jornada time,
    hora_fin_jornada time,
    fecha_contratacion date,
    sueldo decimal(7, 2),
    fecha_registro timestamp not null default current_timestamp,
    sucursal_id bigint not null,
    foreign key (sucursal_id) references sucursales (id),
    primary key (id)
  );

-- Personas naturales y jurídicas
create table if not exists
  tipos_personas (
    id int auto_increment,
    nombre varchar(255) not null,
    primary key (id)
  );

create table if not exists
  clientes (
    id bigint auto_increment,
    nombres_apellidos varchar(511),
    dni varchar(8),
    razon_social varchar(255),
    ruc varchar(20),
    telefono varchar(20),
    correo varchar(255),
    fecha_registro timestamp not null default current_timestamp,
    tipo_persona_id int not null,
    foreign key (tipo_persona_id) references tipos_personas (id),
    primary key (id)
  );

create table if not exists
  roles_cuentas_empleados (
    id bigint auto_increment,
    nombre_rol varchar(255) not null unique,
    primary key (id)
  );

create table if not exists
  cuentas_empleados (
    id bigint auto_increment,
    usuario varchar(100) not null unique,
    clave varchar(255) not null,
    fecha_creacion timestamp not null default current_timestamp,
    rol_cuenta_empleado_id bigint not null,
    empleado_id bigint not null,
    foreign key (rol_cuenta_empleado_id) references roles_cuentas_empleados (id),
    foreign key (empleado_id) references empleados (id),
    primary key (id)
  );

create table if not exists
  permisos (
    id bigint auto_increment,
    nombre_permiso varchar(255) not null unique,
    primary key (id)
  );

create table if not exists
  roles_permisos (
    rol_id bigint not null,
    permiso_id bigint not null,
    foreign key (rol_id) references roles_cuentas_empleados (id),
    foreign key (permiso_id) references permisos (id),
    primary key (rol_id, permiso_id)
  );

create table if not exists
  refresh_tokens_empleados (
    id bigint auto_increment,
    token varchar(255) not null,
    secret varchar(511) not null,
    fecha_creacion timestamp not null default current_timestamp,
    cuenta_empleado_id bigint not null,
    foreign key (cuenta_empleado_id) references cuentas_empleados (id),
    primary key (id)
  );

-- Considerar estado de la proforma de venta ()
create table if not exists
  proformas_venta (
    id bigint auto_increment,
    nombre varchar(255),
    fecha_creacion timestamp not null default current_timestamp,
    detalles jsonb not null,
    empleado_id bigint not null,
    sucursal_id bigint not null,
    foreign key (empleado_id) references empleados (id),
    foreign key (sucursal_id) references sucursales (id),
    primary key (id)
  );

create table if not exists
  metodos_pago (
    id bigint auto_increment,
    nombre varchar(255) not null,
    codigo varchar(20) not null,
    activado boolean not null,
    primary key (id)
  );

create table if not exists
  ventas (
    id bigint auto_increment,
    total decimal(8, 2) not null,
    fecha_creacion timestamp not null default current_timestamp,
    observaciones varchar(511) not null,
    metodo_pago_id bigint not null,
    empleado_id bigint not null,
    cliente_id bigint not null,
    sucursal_id bigint not null,
    foreign key (metodo_pago_id) references metodos_pago (id),
    foreign key (empleado_id) references empleados (id),
    foreign key (cliente_id) references clientes (id),
    foreign key (sucursal_id) references sucursales (id),
    primary key (id)
  );

create table if not exists
  detalles (
    id bigint auto_increment,
    cantidad int not null default 1,
    subtotal decimal(7, 2) not null,
    producto_id bigint,
    grupo_producto_id bigint,
    venta_id bigint not null,
    foreign key (producto_id) references productos (id),
    foreign key (grupo_producto_id) references grupos_productos (id),
    foreign key (venta_id) references ventas (id),
    primary key (id)
  );

-- Monto o porcentaje?
create table if not exists
  descuentos (
    id bigint auto_increment,
    monto decimal(7, 2) not null,
    descripcion varchar(255),
    venta_id bigint not null,
    foreign key (venta_id) references ventas (id),
    primary key (id)
  );

create table if not exists
  devoluciones (
    id bigint auto_increment,
    motivo varchar(1023) not null,
    fecha_devolucion timestamp not null default current_timestamp,
    venta_id bigint not null,
    sucursal_id bigint not null,
    foreign key (venta_id) references ventas (id),
    foreign key (sucursal_id) references sucursales (id),
    primary key (id)
  );

create table if not exists
  entradas_inventarios (
    id bigint auto_increment,
    cantidad bigint not null default 1,
    fecha_movimiento timestamp not null default current_timestamp,
    producto_id bigint not null,
    sucursal_id bigint not null,
    foreign key (producto_id) references productos (id),
    foreign key (sucursal_id) references sucursales (id),
    primary key (id)
  );

create table if not exists
  transferencias_inventarios (
    id bigint auto_increment,
    cantidad int not null,
    fecha_transferencia timestamp not null default current_timestamp,
    producto_id bigint not null,
    sucursal_origen_id bigint not null,
    sucursal_destino_id bigint not null,
    foreign key (producto_id) references productos (id),
    foreign key (sucursal_origen_id) references sucursales (id),
    foreign key (sucursal_destino_id) references sucursales (id),
    primary key (id)
  );

create table if not exists
  reservas_productos (
    id bigint auto_increment,
    cantidad int not null default 1,
    total decimal(7, 2) not null,
    monto_adelantado decimal(7, 2) not null,
    fecha_reserva timestamp not null default current_timestamp,
    cliente_id bigint not null,
    producto_id bigint,
    grupo_producto_id bigint,
    foreign key (cliente_id) references clientes (id),
    foreign key (producto_id) references productos (id),
    foreign key (grupo_producto_id) references grupos_productos (id),
    primary key (id)
  );
