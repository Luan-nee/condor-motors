/* eslint-disable no-console */
import { BcryptAdapter } from '@/config/bcrypt'
import { envs } from '@/config/envs'
import { JwtAdapter } from '@/config/jwt'
import { permissionCodes } from '@/consts'
import { db } from '@db/connection'
import {
  cuentasEmpleadosTable,
  empleadosTable,
  permisosTable,
  rolesCuentasEmpleadosTable,
  rolesPermisosTable,
  sucursalesTable,
  marcasTable
} from '@db/schema'
import { exit } from 'process'

const populateDatabase = async (
  config: ConfigPopulateDb,
  permissions: Array<{ nombrePermiso: string; codigoPermiso: string }>
) => {
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

    await tx.insert(marcasTable).values(config.marca).returning()

    const permisosId = await tx
      .insert(permisosTable)
      .values(permissions)
      .returning({ id: permisosTable.id })

    await tx.insert(rolesPermisosTable).values(
      permisosId.map((permiso) => ({
        permisoId: permiso.id,
        rolId: rolEmpleado.id
      }))
    )
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
    codigo: 'administrador',
    nombreRol: 'Adminstrador'
  },
  marca: {
    nombre: 'Marca Principal',
    descripcion: 'Marca por defecto del sistema'
  }
}

const transformPermissionCodes = (codes: typeof permissionCodes) => {
  const permissionsArray = Object.values(codes).flatMap((category) =>
    Object.values(category).map((code) => ({
      nombrePermiso: code,
      codigoPermiso: code
    }))
  )

  return permissionsArray
}

const permissions = transformPermissionCodes(permissionCodes)

populateDatabase(config, permissions)
  .then((administrador) => {
    console.log('Database has been initialized correctly!')
    console.log('user credentials:', administrador)
    exit()
  })
  .catch((error: unknown) => {
    console.error(error)
    exit(1)
  })
