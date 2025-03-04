import type {
  cuentasEmpleadosTable,
  sucursalesTable,
  empleadosTable,
  rolesCuentasEmpleadosTable
} from '@/db/schema'
import type { InferSelectModel } from 'drizzle-orm'

type RolCuentaEmpleadoEntity = InferSelectModel<
  typeof rolesCuentasEmpleadosTable
>

export type UserEntity = Omit<
  InferSelectModel<typeof cuentasEmpleadosTable>,
  'secret' | 'clave'
> & { rolCuentaEmpleadoCodigo: Pick<RolCuentaEmpleadoEntity, 'codigo'> }

export interface UserEntityWithTokens {
  accessToken: string
  refreshToken: string
  data: UserEntity
}

export type SucursalEntity = InferSelectModel<typeof sucursalesTable>

export type EmpleadoEntity = Omit<
  InferSelectModel<typeof empleadosTable>,
  'sueldo'
> & { sueldo: number }
