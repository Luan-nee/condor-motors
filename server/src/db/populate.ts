/* eslint-disable no-console */
import { BcryptAdapter } from '@/config/bcrypt'
import { JwtAdapter } from '@/config/jwt'
import { permissionCodes } from '@/consts'
import { db } from '@db/connection'
import {
  cuentasEmpleadosTable,
  empleadosTable,
  permisosTable,
  rolesTable,
  rolesPermisosTable,
  sucursalesTable,
  marcasTable,
  categoriasTable
} from '@db/schema'
import { exit } from 'process'
import { populateConfig } from '@db/config/populate.config'

const populateDatabase = async (
  config: PopulateConfig,
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
      .insert(rolesTable)
      .values(config.rolEmpleado)
      .returning()

    await tx.insert(cuentasEmpleadosTable).values({
      usuario: config.user.usuario,
      clave: hashedPassword,
      secret,
      rolCuentaEmpleadoId: rolEmpleado.id,
      empleadoId: empleado.id
    })

    await tx.insert(categoriasTable).values(config.defaultCategoria)
    await tx.insert(marcasTable).values(config.defaultCategoria)

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

const transformPermissionCodes = (codes: typeof permissionCodes) =>
  Object.values(codes).flatMap((category) =>
    Object.values(category).map((code) => ({
      nombrePermiso: code,
      codigoPermiso: code
    }))
  )

const permissions = transformPermissionCodes(permissionCodes)

populateDatabase(populateConfig, permissions)
  .then((administrador) => {
    console.log('Database has been initialized correctly!')
    console.log('user credentials:', administrador)
    exit()
  })
  .catch((error: unknown) => {
    console.error(error)
    exit(1)
  })
