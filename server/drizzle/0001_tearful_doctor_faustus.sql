DROP TABLE "refresh_tokens_empleados" CASCADE;--> statement-breakpoint
ALTER TABLE "cuentas_empleados" ADD COLUMN "secret" text NOT NULL;