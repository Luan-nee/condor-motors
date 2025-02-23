/* eslint-disable no-console */
import { BcryptAdapter } from '@/config/bcrypt'
import { envs } from '@/config/envs'
import { JwtAdapter } from '@/config/jwt'
import { db } from '@db/connection'
import {
  cuentasEmpleadosTable,
  empleadosTable,
  rolesCuentasEmpleadosTable,
  sucursalesTable
} from '@db/schema'
import { exit } from 'process'

// A pesar de que esto es funcional, aún faltaría agregar datos en la tabla de permisos
const populateDatabase = async (config: ConfigPopulateDb) => {
  const hashedPassword = await BcryptAdapter.hash(config.user.clave)
  const secret = JwtAdapter.randomSecret()

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
      secret,
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
    usuario: envs.ADMIN_USER,
    clave: envs.ADMIN_PASSWORD
  },
  sucursal: {
    nombre: 'Sucursal Principal',
    sucursalCentral: true,
    direccion: 'Desconocida'
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
