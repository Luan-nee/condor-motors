/* eslint-disable no-console */
import { BcryptAdapter } from '@/config/bcrypt'
import { JwtAdapter } from '@/config/jwt'
import { db } from '@db/connection'
import {
  cuentasEmpleadosTable,
  empleadosTable,
  permisosTable,
  rolesTable,
  rolesPermisosTable,
  sucursalesTable,
  marcasTable,
  categoriasTable,
  coloresTable
} from '@db/schema'
import { exit } from 'process'
import { adminPermissions, populateConfig } from '@db/config/populate.config'
import { formatCode } from '@/core/lib/format-values'

const populateDatabase = async (
  config: PopulateConfig,
  permissions: Array<{ nombre: string; codigo: string }>
) => {
  const hashedPassword = await BcryptAdapter.hash(config.user.clave)
  const secret = JwtAdapter.randomSecret()

  await db.transaction(async (tx) => {
    const [sucursal] = await tx
      .insert(sucursalesTable)
      .values(config.sucursal)
      .returning({ id: sucursalesTable.id })

    const [empleado] = await tx
      .insert(empleadosTable)
      .values({
        ...config.empleado,
        sucursalId: sucursal.id
      })
      .returning({ id: empleadosTable.id })

    const [adminRole] = await tx
      .insert(rolesTable)
      .values(
        config.rolesDefault.map((rol) => ({
          codigo: formatCode(rol),
          nombre: rol
        }))
      )
      .returning()

    const adminPermissions = await tx
      .insert(permisosTable)
      .values(permissions)
      .returning({ id: permisosTable.id })

    await tx.insert(rolesPermisosTable).values(
      adminPermissions.map((permission) => ({
        permisoId: permission.id,
        rolId: adminRole.id
      }))
    )

    await tx.insert(cuentasEmpleadosTable).values({
      usuario: config.user.usuario,
      clave: hashedPassword,
      secret,
      eliminable: false,
      rolId: adminRole.id,
      empleadoId: empleado.id
    })

    await tx.insert(coloresTable).values(config.coloresDefault)
    await tx.insert(categoriasTable).values(config.defaultCategoria)
    await tx.insert(marcasTable).values(config.defaultCategoria)
  })

  return {
    usuario: config.user.usuario,
    clave: config.user.clave
  }
}

const permissions = adminPermissions

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
