import type {
  cuentasEmpleadosTable,
  sucursalesTable,
  empleadosTable,
  rolesCuentasEmpleadosTable,
  productosTable,
  unidadesTable,
  categoriasTable,
  marcasTable
} from '@/db/schema'
import type { InferSelectModel } from 'drizzle-orm'

type RolCuentaEmpleadoEntity = InferSelectModel<
  typeof rolesCuentasEmpleadosTable
>

export type UserEntity = Omit<
  InferSelectModel<typeof cuentasEmpleadosTable>,
  'secret' | 'clave'
> & { rolCuentaEmpleadoCodigo: RolCuentaEmpleadoEntity['codigo'] }

export interface UserEntityWithTokens {
  accessToken: string
  refreshToken: string
  data: UserEntity
}

export type SucursalEntity = InferSelectModel<typeof sucursalesTable>

export type EmpleadoEntity = InferSelectModel<typeof empleadosTable>

type UnidadEntity = InferSelectModel<typeof unidadesTable>
type CategoriaEntity = InferSelectModel<typeof categoriasTable>
type MarcaEntity = InferSelectModel<typeof marcasTable>

export interface RelacionadosProductoEntity {
  unidadNombre: UnidadEntity['nombre']
  categoriaNombre: CategoriaEntity['nombre']
  marcaNombre: MarcaEntity['nombre']
}

export type ProductoEntity = InferSelectModel<typeof productosTable> & {
  relacionados: RelacionadosProductoEntity
}
