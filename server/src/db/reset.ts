/* eslint-disable no-console */
import { envs } from '@/config/envs'
import { db } from '@db/connection'
import * as schema from '@db/schema'
import { reset } from 'drizzle-seed'
import { exit } from 'process'

const resetDatabase = async () => {
  const newSchema = {
    sucursales: schema.sucursalesTable,
    empleados: schema.empleadosTable,
    roles: schema.rolesCuentasEmpleadosTable
  }

  await reset(db, newSchema)
}

const { NODE_ENV: nodeEnv } = envs

if (nodeEnv !== 'production') {
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
