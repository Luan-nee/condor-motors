/* eslint-disable no-console */
import { BcryptAdapter } from '@/config/bcrypt'
import { db } from '@db/connection'
import { exit } from 'process'
import {
  cuentasEmpleadosTable,
  empleadosTable,
  rolesCuentasEmpleadosTable,
  sucursalesTable
} from './schema'

// A pesar de que esto es funcional, aún faltaría agregar datos en la tabla de permisos
const populateDatabase = async (config: ConfigPopulateDb) => {
  const hashedPassword = await BcryptAdapter.hash(config.user.clave)

  await db.transaction(async (tx) => {
    const [sucursal] = await tx
      .insert(sucursalesTable)
      .values(config.sucursal)
      .returning()

    const [empleado] = await tx
      .insert(empleadosTable)
      .values({
        ...config.empleado,
        sucursalId: sucursal.id
      })
      .returning()

    const [rolEmpleado] = await tx
      .insert(rolesCuentasEmpleadosTable)
      .values(config.rolEmpleado)
      .returning()

    await tx.insert(cuentasEmpleadosTable).values({
      usuario: config.user.usuario,
      clave: hashedPassword,
      rolCuentaEmpleadoId: rolEmpleado.id,
      empleadoId: empleado.id
    })
  })

  return {
    usuario: config.user.usuario,
    clave: config.user.clave
  }
}

const config: ConfigPopulateDb = {
  user: {
    usuario: 'Administrador',
    clave: 'Admin123'
  },
  sucursal: {
    nombre: 'Sucursal Principal',
    sucursalCentral: true,
    fechaRegistro: new Date(),
    ubicacion: 'Desconocida'
  },
  empleado: {
    nombre: 'Administrador',
    apellidos: 'Principal'
  },
  rolEmpleado: {
    nombreRol: 'Adminstrador'
  }
}

populateDatabase(config)
  .then((administrador) => {
    console.log('Database has been initialized correctly!')
    console.log('user credentials:', administrador)
    exit()
  })
  .catch((error: unknown) => {
    console.error(error)
    exit(1)
  })
