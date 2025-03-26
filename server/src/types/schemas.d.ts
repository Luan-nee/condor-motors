import type {
  cuentasEmpleadosTable,
  sucursalesTable,
  empleadosTable,
  rolesTable,
  productosTable,
  categoriasTable,
  marcasTable,
  coloresTable,
  detallesProductoTable
} from '@/db/schema'
import type { InferSelectModel } from 'drizzle-orm'

type RolCuentaEmpleadoEntity = InferSelectModel<typeof rolesTable>

export type UserEntity = Omit<
  InferSelectModel<typeof cuentasEmpleadosTable>,
  'secret' | 'clave'
> & { rolCuentaEmpleadoCodigo: RolCuentaEmpleadoEntity['codigo'] } & {
  sucursal: SucursalEntity['nombre']
  sucursalId: SucursalEntity['id']
}

export interface UserEntityWithTokens {
  accessToken: string
  refreshToken: string
  data: UserEntity
}

export type SucursalEntity = InferSelectModel<typeof sucursalesTable>
export type SucursalIdType = SucursalEntity['id']

export type EmpleadoEntity = InferSelectModel<typeof empleadosTable>

type ColorEntity = InferSelectModel<typeof coloresTable>
type CategoriaEntity = InferSelectModel<typeof categoriasTable>
type MarcaEntity = InferSelectModel<typeof marcasTable>

interface RelacionadosProductoEntity {
  colorNombre: ColorEntity['nombre']
  categoriaNombre: CategoriaEntity['nombre']
  marcaNombre: MarcaEntity['nombre']
}

export type DetallesProductoEntity = Omit<
  InferSelectModel<typeof detallesProductoTable>,
  'id' | 'fechaCreacion' | 'fechaActualizacion' | 'productoId' | 'sucursalId'
>

export type ProductoEntity = InferSelectModel<typeof productosTable> &
  DetallesProductoEntity & {
    relacionados: RelacionadosProductoEntity
  }
