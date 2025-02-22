import type { cuentasEmpleadosTable, sucursalesTable } from '@/db/schema'
import type { InferSelectModel } from 'drizzle-orm'

export type UserEntity = Omit<
  InferSelectModel<typeof cuentasEmpleadosTable>,
  'secret' | 'clave'
>

export interface UserEntityWithTokens {
  accessToken: string
  refreshToken: string
  data: UserEntity
}

export type SucursalEntity = InferSelectModel<typeof sucursalesTable>
