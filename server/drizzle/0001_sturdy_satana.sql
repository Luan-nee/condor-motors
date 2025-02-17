CREATE TABLE "estados_transferencias_inventarios" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "estados_transferencias_inventarios_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"nombre" text NOT NULL,
	"codigo" text NOT NULL,
	CONSTRAINT "estados_transferencias_inventarios_nombre_unique" UNIQUE("nombre"),
	CONSTRAINT "estados_transferencias_inventarios_codigo_unique" UNIQUE("codigo")
);
--> statement-breakpoint
ALTER TABLE "transferencias_inventarios" ADD COLUMN "estado_transferencia_id" integer NOT NULL;--> statement-breakpoint
ALTER TABLE "transferencias_inventarios" ADD CONSTRAINT "transferencias_inventarios_estado_transferencia_id_estados_transferencias_inventarios_id_fk" FOREIGN KEY ("estado_transferencia_id") REFERENCES "public"."estados_transferencias_inventarios"("id") ON DELETE no action ON UPDATE no action;