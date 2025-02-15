/* Estas tablas son solo de referencia no se incluyen directamente en la aplicación ni en la base de datos principal */
-- Tablas de ejemplo para gestionar los documentos (facturas y boletas)
create table
  emisor (
    id int auto_increment primary key,
    codigo_establecimiento varchar(10)
  );

create table
  cliente (
    id int auto_increment primary key,
    cliente_tipo_documento varchar(10),
    cliente_numero_documento varchar(20),
    cliente_denominacion varchar(100),
    codigo_pais varchar(10),
    ubigeo varchar(10),
    cliente_direccion varchar(255),
    cliente_email varchar(100),
    cliente_telefono varchar(20)
  );

create table
  totales (
    id int auto_increment primary key,
    total_exportacion decimal(10, 2),
    total_gravadas decimal(10, 2),
    total_inafectas decimal(10, 2),
    total_exoneradas decimal(10, 2),
    total_gratuitas decimal(10, 2),
    total_otros_cargos decimal(10, 2),
    total_tax decimal(10, 2),
    total_venta decimal(10, 2)
  );

create table
  acciones (
    id int auto_increment primary key,
    formato_pdf varchar(10)
  );

create table
  terminopago (
    id int auto_increment primary key,
    descripcion varchar(50),
    tipo varchar(10)
  );

create table
  documento (
    id int auto_increment primary key,
    tipo_documento varchar(10) not null,
    serie varchar(10) not null,
    numero varchar(20) not null,
    tipo_operacion varchar(10) not null,
    fecha_de_emision date not null,
    hora_de_emision time,
    moneda varchar(10) not null,
    porcentaje_de_venta decimal(5, 2) not null,
    fecha_de_vencimiento date,
    enviar_automaticamente_al_cliente boolean,
    forma_de_pago varchar(50),
    numero_orden varchar(50),
    codigo varchar(50),
    observaciones text,
    emisor_id int,
    cliente_id int,
    totales_id int,
    acciones_id int,
    termino_pago_id int,
    foreign key (emisor_id) references emisor (id),
    foreign key (cliente_id) references cliente (id),
    foreign key (totales_id) references totales (id),
    foreign key (acciones_id) references acciones (id),
    foreign key (termino_pago_id) references terminopago (id)
  );

create table
  items (
    id int auto_increment primary key,
    unidad varchar(10),
    codigo varchar(50),
    descripcion varchar(255),
    codigo_producto_sunat varchar(50),
    codigo_producto_gsl varchar(50),
    cantidad int,
    valor_unitario decimal(10, 2),
    precio_unitario decimal(10, 2),
    tipo_tax varchar(10),
    total_base_tax decimal(10, 2),
    total_tax decimal(10, 2),
    total decimal(10, 2),
    documento_id int,
    foreign key (documento_id) references documento (id)
  );
