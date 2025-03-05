/* eslint-disable no-console */
import { envs } from '@/config/envs'
import { isProduction } from '@/consts'
import { db } from '@db/connection'
import * as schema from '@db/schema'
import { reset } from 'drizzle-seed'
import { exit } from 'process'

const resetDatabase = async () => {
  const newSchema = {
    sucursales: schema.sucursalesTable,
    empleados: schema.empleadosTable,
    roles: schema.rolesCuentasEmpleadosTable,
    rolesPermisos: schema.rolesPermisosTable,
    permisos: schema.permisosTable,
    unidades: schema.unidadesTable,
    categorias: schema.categoriasTable,
    marcas: schema.marcasTable,
    productos: schema.productosTable
  }

  await reset(db, newSchema)
}

const { NODE_ENV: nodeEnv } = envs

if (!isProduction) {
  resetDatabase()
    .then(() => {
      exit()
    })
    .catch((error: unknown) => {
      console.error(error)
      exit(1)
    })
} else {
  console.log(`Database not modified`)
  console.log(`You are in ${nodeEnv} enviroment`)
}
