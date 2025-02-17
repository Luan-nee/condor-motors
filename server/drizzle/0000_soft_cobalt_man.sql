CREATE TABLE "categorias" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "categorias_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"nombre" text NOT NULL,
	"descripcion" text,
	CONSTRAINT "categorias_nombre_unique" UNIQUE("nombre")
);
--> statement-breakpoint
CREATE TABLE "clientes" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "clientes_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"nombres_apellidos" text,
	"dni" text,
	"razon_social" text,
	"ruc" text,
	"telefono" text,
	"correo" text,
	"fecha_registro" timestamp with time zone DEFAULT now() NOT NULL,
	"tipo_persona_id" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "cuentas_empleados" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "cuentas_empleados_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"usuario" text NOT NULL,
	"clave" text NOT NULL,
	"fecha_registro" timestamp with time zone DEFAULT now() NOT NULL,
	"rol_cuenta_empleado_id" integer NOT NULL,
	"empleado_id" integer NOT NULL,
	CONSTRAINT "cuentas_empleados_usuario_unique" UNIQUE("usuario")
);
--> statement-breakpoint
CREATE TABLE "descuentos" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "descuentos_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"monto" numeric(7, 2) NOT NULL,
	"descripcion" text,
	"venta_id" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "detalles" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "detalles_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"cantidad" integer DEFAULT 1 NOT NULL,
	"subtotal" numeric(7, 2) NOT NULL,
	"producto_id" integer,
	"grupo_producto_id" integer,
	"venta_id" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "devoluciones" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "devoluciones_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"motivo" text NOT NULL,
	"fecha_devolucion" timestamp with time zone DEFAULT now() NOT NULL,
	"venta_id" integer NOT NULL,
	"sucursal_id" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "empleados" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "empleados_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"nombre" text NOT NULL,
	"apellidos" text NOT NULL,
	"ubicacion_foto" text,
	"edad" integer,
	"dni" text,
	"hora_inicio_jornada" time with time zone,
	"hora_fin_jornada" time with time zone,
	"fechaContratacion" date,
	"sueldo" numeric(7, 2),
	"fecha_registro" timestamp with time zone DEFAULT now() NOT NULL,
	"sucursal_id" integer NOT NULL,
	CONSTRAINT "empleados_nombre_unique" UNIQUE("nombre"),
	CONSTRAINT "empleados_apellidos_unique" UNIQUE("apellidos")
);
--> statement-breakpoint
CREATE TABLE "entradas_inventarios" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "entradas_inventarios_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"cantidad" integer DEFAULT 1 NOT NULL,
	"fecha_movimiento" timestamp with time zone DEFAULT now() NOT NULL,
	"producto_id" integer NOT NULL,
	"sucursal_id" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "fotos_productos" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "fotos_productos_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"ubicacion" text NOT NULL,
	"producto_id" integer,
	"grupo_producto_id" integer
);
--> statement-breakpoint
CREATE TABLE "grupos_productos" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "grupos_productos_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"nombre" text NOT NULL,
	"cantidad_grupo" integer DEFAULT 2 NOT NULL,
	"producto_id" integer NOT NULL,
	CONSTRAINT "grupos_productos_nombre_unique" UNIQUE("nombre")
);
--> statement-breakpoint
CREATE TABLE "inventarios" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "inventarios_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"stock" integer DEFAULT 0 NOT NULL,
	"fecha_stock_reabastecido" timestamp with time zone DEFAULT now() NOT NULL,
	"producto_id" integer NOT NULL,
	"sucursal_id" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "marcas" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "marcas_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"nombre" text NOT NULL,
	"descripcion" text,
	CONSTRAINT "marcas_nombre_unique" UNIQUE("nombre")
);
--> statement-breakpoint
CREATE TABLE "metodos_pago" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "metodos_pago_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"nombre" text NOT NULL,
	"codigo" text NOT NULL,
	"activado" boolean NOT NULL,
	CONSTRAINT "metodos_pago_nombre_unique" UNIQUE("nombre"),
	CONSTRAINT "metodos_pago_codigo_unique" UNIQUE("codigo")
);
--> statement-breakpoint
CREATE TABLE "notificaciones" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "notificaciones_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"titulo" text NOT NULL,
	"descripcion" text,
	"sucursal_id" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "permisos" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "permisos_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"nombre_permiso" text NOT NULL,
	CONSTRAINT "permisos_nombre_permiso_unique" UNIQUE("nombre_permiso")
);
--> statement-breakpoint
CREATE TABLE "precios_productos" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "precios_productos_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"precio_base" numeric(7, 2),
	"precio_mayorista" numeric(7, 2),
	"precio_oferta" numeric(7, 2),
	"producto_id" integer,
	"grupo_producto_id" integer,
	"sucursal_id" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "productos" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "productos_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"sku" text NOT NULL,
	"nombre" text NOT NULL,
	"descripcion" text,
	"max_dias_sin_reabastecer" integer DEFAULT 30,
	"unidad_id" integer NOT NULL,
	"categoria_id" integer NOT NULL,
	"marca_id" integer NOT NULL,
	CONSTRAINT "productos_sku_unique" UNIQUE("sku"),
	CONSTRAINT "productos_nombre_unique" UNIQUE("nombre")
);
--> statement-breakpoint
CREATE TABLE "proformas_venta" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "proformas_venta_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"nombre" text,
	"fecha_creacion" timestamp with time zone DEFAULT now() NOT NULL,
	"detalles" jsonb NOT NULL,
	"empleado_id" integer NOT NULL,
	"sucursal_id" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "refresh_tokens_empleados" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "refresh_tokens_empleados_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"token" text NOT NULL,
	"secret" text NOT NULL,
	"fecha_creacion" timestamp with time zone DEFAULT now() NOT NULL,
	"cuenta_empleado_id" integer NOT NULL,
	CONSTRAINT "refresh_tokens_empleados_token_unique" UNIQUE("token")
);
--> statement-breakpoint
CREATE TABLE "reservas_productos" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "reservas_productos_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"cantidad" integer DEFAULT 1 NOT NULL,
	"total" numeric(7, 2) NOT NULL,
	"monto_adelantado" numeric(7, 2) NOT NULL,
	"fecha_reserva" timestamp with time zone DEFAULT now() NOT NULL,
	"cliente_id" integer NOT NULL,
	"sucursal_id" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "roles_cuentas_empleados" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "roles_cuentas_empleados_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"nombre_rol" text NOT NULL,
	CONSTRAINT "roles_cuentas_empleados_nombre_rol_unique" UNIQUE("nombre_rol")
);
--> statement-breakpoint
CREATE TABLE "roles_permisos" (
	"rol_id" integer NOT NULL,
	"permiso_id" integer NOT NULL,
	CONSTRAINT "roles_permisos_rol_id_permiso_id_pk" PRIMARY KEY("rol_id","permiso_id")
);
--> statement-breakpoint
CREATE TABLE "sucusales" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "sucusales_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"nombre" text NOT NULL,
	"ubicacion" text,
	"sucursal_central" boolean NOT NULL,
	"fecha_registro" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "sucusales_nombre_unique" UNIQUE("nombre")
);
--> statement-breakpoint
CREATE TABLE "tipos_personas" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "tipos_personas_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"nombre" text NOT NULL,
	CONSTRAINT "tipos_personas_nombre_unique" UNIQUE("nombre")
);
--> statement-breakpoint
CREATE TABLE "transferencias_inventarios" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "transferencias_inventarios_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"cantidad" integer DEFAULT 1 NOT NULL,
	"fecha_transferencia" timestamp with time zone DEFAULT now() NOT NULL,
	"producto_id" integer NOT NULL,
	"sucursal_origen_id" integer NOT NULL,
	"sucursal_destino_id" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "unidades" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "unidades_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"nombre" text NOT NULL,
	CONSTRAINT "unidades_nombre_unique" UNIQUE("nombre")
);
--> statement-breakpoint
CREATE TABLE "ventas" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "ventas_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"total" numeric(8, 2) NOT NULL,
	"fecha_creacion" timestamp with time zone DEFAULT now() NOT NULL,
	"observaciones" text,
	"metodo_pago_id" integer NOT NULL,
	"cliente_id" integer NOT NULL,
	"empleado_id" integer NOT NULL,
	"sucursal_id" integer NOT NULL
);
--> statement-breakpoint
ALTER TABLE "clientes" ADD CONSTRAINT "clientes_tipo_persona_id_tipos_personas_id_fk" FOREIGN KEY ("tipo_persona_id") REFERENCES "public"."tipos_personas"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "cuentas_empleados" ADD CONSTRAINT "cuentas_empleados_rol_cuenta_empleado_id_roles_cuentas_empleados_id_fk" FOREIGN KEY ("rol_cuenta_empleado_id") REFERENCES "public"."roles_cuentas_empleados"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "cuentas_empleados" ADD CONSTRAINT "cuentas_empleados_empleado_id_empleados_id_fk" FOREIGN KEY ("empleado_id") REFERENCES "public"."empleados"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "descuentos" ADD CONSTRAINT "descuentos_venta_id_ventas_id_fk" FOREIGN KEY ("venta_id") REFERENCES "public"."ventas"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "detalles" ADD CONSTRAINT "detalles_producto_id_productos_id_fk" FOREIGN KEY ("producto_id") REFERENCES "public"."productos"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "detalles" ADD CONSTRAINT "detalles_grupo_producto_id_grupos_productos_id_fk" FOREIGN KEY ("grupo_producto_id") REFERENCES "public"."grupos_productos"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "detalles" ADD CONSTRAINT "detalles_venta_id_ventas_id_fk" FOREIGN KEY ("venta_id") REFERENCES "public"."ventas"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "devoluciones" ADD CONSTRAINT "devoluciones_venta_id_ventas_id_fk" FOREIGN KEY ("venta_id") REFERENCES "public"."ventas"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "devoluciones" ADD CONSTRAINT "devoluciones_sucursal_id_sucusales_id_fk" FOREIGN KEY ("sucursal_id") REFERENCES "public"."sucusales"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "empleados" ADD CONSTRAINT "empleados_sucursal_id_sucusales_id_fk" FOREIGN KEY ("sucursal_id") REFERENCES "public"."sucusales"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entradas_inventarios" ADD CONSTRAINT "entradas_inventarios_producto_id_productos_id_fk" FOREIGN KEY ("producto_id") REFERENCES "public"."productos"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entradas_inventarios" ADD CONSTRAINT "entradas_inventarios_sucursal_id_sucusales_id_fk" FOREIGN KEY ("sucursal_id") REFERENCES "public"."sucusales"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fotos_productos" ADD CONSTRAINT "fotos_productos_producto_id_productos_id_fk" FOREIGN KEY ("producto_id") REFERENCES "public"."productos"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fotos_productos" ADD CONSTRAINT "fotos_productos_grupo_producto_id_grupos_productos_id_fk" FOREIGN KEY ("grupo_producto_id") REFERENCES "public"."grupos_productos"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "grupos_productos" ADD CONSTRAINT "grupos_productos_producto_id_productos_id_fk" FOREIGN KEY ("producto_id") REFERENCES "public"."productos"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventarios" ADD CONSTRAINT "inventarios_producto_id_productos_id_fk" FOREIGN KEY ("producto_id") REFERENCES "public"."productos"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventarios" ADD CONSTRAINT "inventarios_sucursal_id_sucusales_id_fk" FOREIGN KEY ("sucursal_id") REFERENCES "public"."sucusales"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "notificaciones" ADD CONSTRAINT "notificaciones_sucursal_id_sucusales_id_fk" FOREIGN KEY ("sucursal_id") REFERENCES "public"."sucusales"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "precios_productos" ADD CONSTRAINT "precios_productos_producto_id_productos_id_fk" FOREIGN KEY ("producto_id") REFERENCES "public"."productos"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "precios_productos" ADD CONSTRAINT "precios_productos_grupo_producto_id_grupos_productos_id_fk" FOREIGN KEY ("grupo_producto_id") REFERENCES "public"."grupos_productos"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "precios_productos" ADD CONSTRAINT "precios_productos_sucursal_id_sucusales_id_fk" FOREIGN KEY ("sucursal_id") REFERENCES "public"."sucusales"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "productos" ADD CONSTRAINT "productos_unidad_id_unidades_id_fk" FOREIGN KEY ("unidad_id") REFERENCES "public"."unidades"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "productos" ADD CONSTRAINT "productos_categoria_id_unidades_id_fk" FOREIGN KEY ("categoria_id") REFERENCES "public"."unidades"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "productos" ADD CONSTRAINT "productos_marca_id_unidades_id_fk" FOREIGN KEY ("marca_id") REFERENCES "public"."unidades"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "proformas_venta" ADD CONSTRAINT "proformas_venta_empleado_id_empleados_id_fk" FOREIGN KEY ("empleado_id") REFERENCES "public"."empleados"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "proformas_venta" ADD CONSTRAINT "proformas_venta_sucursal_id_sucusales_id_fk" FOREIGN KEY ("sucursal_id") REFERENCES "public"."sucusales"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "refresh_tokens_empleados" ADD CONSTRAINT "refresh_tokens_empleados_cuenta_empleado_id_cuentas_empleados_id_fk" FOREIGN KEY ("cuenta_empleado_id") REFERENCES "public"."cuentas_empleados"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "reservas_productos" ADD CONSTRAINT "reservas_productos_cliente_id_clientes_id_fk" FOREIGN KEY ("cliente_id") REFERENCES "public"."clientes"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "reservas_productos" ADD CONSTRAINT "reservas_productos_sucursal_id_sucusales_id_fk" FOREIGN KEY ("sucursal_id") REFERENCES "public"."sucusales"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "roles_permisos" ADD CONSTRAINT "roles_permisos_rol_id_roles_cuentas_empleados_id_fk" FOREIGN KEY ("rol_id") REFERENCES "public"."roles_cuentas_empleados"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "roles_permisos" ADD CONSTRAINT "roles_permisos_permiso_id_permisos_id_fk" FOREIGN KEY ("permiso_id") REFERENCES "public"."permisos"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transferencias_inventarios" ADD CONSTRAINT "transferencias_inventarios_producto_id_productos_id_fk" FOREIGN KEY ("producto_id") REFERENCES "public"."productos"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transferencias_inventarios" ADD CONSTRAINT "transferencias_inventarios_sucursal_origen_id_sucusales_id_fk" FOREIGN KEY ("sucursal_origen_id") REFERENCES "public"."sucusales"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transferencias_inventarios" ADD CONSTRAINT "transferencias_inventarios_sucursal_destino_id_sucusales_id_fk" FOREIGN KEY ("sucursal_destino_id") REFERENCES "public"."sucusales"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ventas" ADD CONSTRAINT "ventas_metodo_pago_id_metodos_pago_id_fk" FOREIGN KEY ("metodo_pago_id") REFERENCES "public"."metodos_pago"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ventas" ADD CONSTRAINT "ventas_cliente_id_clientes_id_fk" FOREIGN KEY ("cliente_id") REFERENCES "public"."clientes"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ventas" ADD CONSTRAINT "ventas_empleado_id_empleados_id_fk" FOREIGN KEY ("empleado_id") REFERENCES "public"."empleados"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ventas" ADD CONSTRAINT "ventas_sucursal_id_sucusales_id_fk" FOREIGN KEY ("sucursal_id") REFERENCES "public"."sucusales"("id") ON DELETE no action ON UPDATE no action;