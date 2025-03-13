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
export type SucursalIdType = SucursalEntity['id']

export type EmpleadoEntity = InferSelectModel<typeof empleadosTable>

type UnidadEntity = InferSelectModel<typeof unidadesTable>
type CategoriaEntity = InferSelectModel<typeof categoriasTable>
type MarcaEntity = InferSelectModel<typeof marcasTable>

interface RelacionadosProductoEntity {
  unidadNombre: UnidadEntity['nombre']
  categoriaNombre: CategoriaEntity['nombre']
  marcaNombre: MarcaEntity['nombre']
}

type PreciosProductoEntity = Pick<
  InferSelectModel<typeof preciosProductosTable>,
  'precioBase' | 'precioMayorista' | 'precioOferta'
>

type InventarioEntity = InferSelectModel<typeof inventariosTable>
type InventarioProductoEntity = Pick<InventarioEntity, 'stock'>

export type ProductoEntity = InferSelectModel<typeof productosTable> &
  PreciosProductoEntity &
  InventarioProductoEntity & { relacionados: RelacionadosProductoEntity }
