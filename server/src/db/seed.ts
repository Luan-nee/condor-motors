/* eslint-disable no-console */
import { envs, isProduction } from '@/config/envs'
import { db } from '@db/connection'
import * as schema from '@db/schema'
import { seed } from 'drizzle-seed'
import { exit } from 'process'

const seedDatabase = async () => {
  const newSchema = {
    sucursales: schema.sucursalesTable,
    empleados: schema.empleadosTable,
    rolesCuentas: schema.rolesCuentasEmpleadosTable
  }

  await seed(db, newSchema).refine((f) => ({
    sucursales: {
      count: 3,
      with: {
        empleados: 2
      },
      columns: {
        nombre: f.companyName(),
        ubicacion: f.streetAddress()
      }
    },
    empleados: {
      columns: {
        nombre: f.firstName(),
        apellidos: f.lastName(),
        edad: f.int({
          minValue: 18,
          maxValue: 50
        }),
        sueldo: f.number({
          minValue: 1000,
          maxValue: 3000,
          precision: 2
        })
      }
    },
    rolesCuentas: {
      count: 1,
      columns: {
        nombreRol: f.jobTitle()
      }
    }
  }))
}

const { NODE_ENV: nodeEnv } = envs

if (!isProduction) {
  seedDatabase()
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
