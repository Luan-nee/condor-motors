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

type UnidadEntity = InferSelectModel<typeof unidadesTable>
type CategoriaEntity = InferSelectModel<typeof categoriasTable>
type MarcaEntity = InferSelectModel<typeof marcasTable>

export interface RelacionadosProductoEntity {
  unidadNombre: Pick<UnidadEntity, 'nombre'>
  categoriaNombre: Pick<CategoriaEntity, 'nombre'>
  marcaNombre: Pick<MarcaEntity, 'nombre'>
}

export type ProductoEntity = InferSelectModel<typeof productosTable> & {
  relacionados: RelacionadosProductoEntity
}
