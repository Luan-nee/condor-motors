/* 
 * Este es solo un diseño temprano de la base de datos, no se recomienda ejecutar este script sql directamente en su equipo
 */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 * [Tablas]:
 * sucursales
 * unidades
 * categorias
 * productos
 * inventarios
 * empleados
 * personas_naturales
 * personas_juridicas
 * clientes
 * roles_cuentas_empleado
 * cuentas_empleados
 * refresh_tokens
 * proformas_venta vs ordenes_compra
 * detalles
 * metodos_pago
 * ventas
 * entradas_inventarios
 * transferencias_inventarios
 * facturas? boletas?
 * reservas (pedidos especiales)
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
 * [Comentarios]:
 * Quizás se podrían separar las cuentas de administración y clientes en tablas diferentes?
 * 
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
-- drop database if exists condor_motors_db;
create database if not exists condor_motors_db;

use condor_motors_db;

create table if not exists
  sucursales (
    id bigint auto_increment,
    nombre varchar(255) not null unique,
    ubicacion varchar(255),
    fecha_registro timestamp not null default current_timestamp,
    primary key (id)
  );

create table if not exists
  unidades (
    id bigint auto_increment,
    nombre varchar(100) not null,
    primary key (id)
  );

create table if not exists
  categorias (
    id bigint auto_increment,
    nombre varchar(100) not null,
    primary key (id)
  );

create table if not exists
  productos (
    id bigint auto_increment,
    nombre varchar(255) not null unique,
    descripcion varchar(255) not null,
    precio decimal(7, 2) not null,
    unidad_id bigint not null,
    categoria_id bigint not null,
    /* 
     * sku??? 
     */
    foreign key (unidad_id) references unidades (id),
    foreign key (categoria_id) references categorias (id),
    primary key (id)
  );

create table if not exists
  inventarios (
    id bigint auto_increment,
    stock bigint default 0 not null,
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
    /* 
     * ¿Qué otros datos del empleado se necesitan?
     * dni?? (desde el tipo de documento o quizás no)
     * sueldo??
     * teléfono??
     * hora inicio jornada?
     * hora fin jornada?
     * fecha contratación?
     * fecha de pago próximo?
     * foto?
     * rol_empleado (de otra tabla)
     */
    fecha_registro timestamp not null default current_timestamp,
    sucursal_id bigint not null,
    foreign key (sucursal_id) references sucursales (id),
    primary key (id)
  );

/* 
 * Aún no estoy 100% seguro sobre estas tablas
 */
create table if not exists
  personas_naturales (
    id bigint auto_increment,
    nombre varchar(255) not null,
    apellidos varchar(255) not null,
    fecha_registro timestamp not null default current_timestamp,
    primary key (id)
  );

create table if not exists
  personas_juridicas (
    id bigint auto_increment,
    ruc varchar(20) not null,
    razon_social varchar(255) not null,
    fecha_registro timestamp not null default current_timestamp,
    primary key (id)
  );

-- son personas naturales o jurídicas?
create table if not exists
  clientes (
    id bigint auto_increment,
    telefono varchar(9),
    -- correo varchar(255),
    persona_natural_id bigint,
    persona_juridica_id bigint,
    foreign key (persona_natural_id) references personas_naturales (id),
    foreign key (persona_juridica_id) references personas_juridicas (id),
    primary key (id)
  );

create table if not exists
  roles_cuentas_empleado (
    id bigint auto_increment,
    nombre_rol varchar(255) not null unique,
    primary key (id)
  );

/* 
 * Renombrar esta tabla como cuentas_empleados 
 */
create table if not exists
  cuentas_empleados (
    id bigint auto_increment,
    usuario varchar(100) not null unique,
    -- correo varchar(255) not null unique,
    clave varchar(255) not null,
    rol_cuenta_empleado_id bigint not null,
    empleado_id bigint not null,
    fecha_creacion timestamp not null default current_timestamp,
    foreign key (rol_cuenta_empleado_id) references roles_cuentas_empleado (id),
    foreign key (empleado_id) references empleados (id),
    primary key (id)
  );

create table if not exists
  refresh_tokens (
    id bigint auto_increment,
    usuario_id bigint not null,
    token varchar(255) not null,
    secreto varchar(255) not null,
    primary key (id)
  );

create table if not exists
  proformas_venta (
    id bigint auto_increment,
    total decimal(8, 2) not null,
    fecha_creacion timestamp not null default current_timestamp,
    empleado_id bigint not null,
    foreign key (empleado_id) references empleados (id),
    primary key (id)
  );

create table if not exists
  detalles (
    id bigint auto_increment,
    cantidad int not null default 1,
    subtotal decimal(7, 2) not null,
    producto_id bigint not null,
    proforma_venta_id bigint not null,
    foreign key (producto_id) references productos (id),
    foreign key (proforma_venta_id) references proformas_venta (id),
    primary key (id)
  );

/*
 * 
 * tabla facturas???
 * tabla boletas???
 * tabla general de comprobantes venta???
 * agregar campo observaciones en dicha tabla
 *
 */
create table if not exists
  metodos_pago (
    id bigint auto_increment,
    nombre varchar(255) not null,
    primary key (id)
  );

create table if not exists
  ventas (
    id bigint auto_increment,
    total decimal(8, 2) not null,
    metodo_pago_id bigint not null,
    fecha_creacion timestamp not null default current_timestamp,
    -- Las observaciones deberían estar aquí?
    observaciones varchar(511) not null,
    /* 
     * Clave foránea no obligatoria del comprobante de venta?
     */
    empleado_id bigint not null,
    cliente_id bigint not null,
    foreign key (empleado_id) references empleados (id),
    foreign key (cliente_id) references clientes (id),
    primary key (id)
  );

/* 
 * tabla de devoluciones???
 */
-- create table if not exists
--   movimientos_inventarios (
--     id bigint auto_increment,
--     cantidad bigint not null default 1,
--     fecha_movimiento timestamp not null default current_timestamp,
--     producto_id bigint not null,
--     inventario_id bigint not null,
--     foreign key (producto_id) references productos (id),
--     foreign key (inventario_id) references inventarios (id),
--     primary key (id)
--   );
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

create table
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
