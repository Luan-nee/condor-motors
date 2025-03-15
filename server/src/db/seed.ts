/* eslint-disable no-console */
import { BcryptAdapter } from '@/config/bcrypt'
import { envs } from '@/config/envs'
import { JwtAdapter } from '@/config/jwt'
import { isProduction } from '@/consts'
import { formatCode } from '@/core/lib/format-values'
import { getRandomValueFromArray } from '@/core/lib/utils'
import { db } from '@db/connection'
import * as schema from '@db/schema'
import { faker } from '@faker-js/faker'
import { exit } from 'process'
import {
  adminPermissions,
  seedConfig,
  vendedorPermisssions,
  computadoraPermissions
} from '@db/config/seed.config'

const sucursalesValues = Array.from({ length: seedConfig.sucursalesCount }).map(
  (_, i) => {
    if (i === 0) {
      return {
        nombre: 'Sucursal Principal',
        sucursalCentral: true,
        direccion: faker.location.streetAddress({ useFullAddress: true })
      }
    }

    return {
      nombre: faker.company.name() + i.toString(),
      sucursalCentral: faker.datatype.boolean(),
      direccion: faker.location.streetAddress({ useFullAddress: true })
    }
  }
)

const rolesValues = seedConfig.rolesDefault.map((rol) => ({
  codigo: formatCode(rol),
  nombreRol: rol
}))

const categoriasValues = seedConfig.categoriasDefault.map((categoria) => ({
  nombre: categoria,
  descripcion: faker.lorem.words({ min: 10, max: 20 })
}))

const marcasValues = seedConfig.marcasDefault.map((marca) => ({
  nombre: marca,
  descripcion: faker.lorem.words({ min: 10, max: 20 })
}))

const coloresValues = seedConfig.coloresDefault.map((color) => ({
  nombre: color
}))

const estadosTransferenciasInventariosValues =
  seedConfig.estadosTransferenciasInventariosDefault.map((estado) => ({
    nombre: estado,
    codigo: formatCode(estado)
  }))

const tiposPersonasValues = seedConfig.tiposPersonasDefault.map(
  (tipoPersona) => ({
    nombre: tipoPersona,
    codigo: formatCode(tipoPersona)
  })
)

const { cuentas } = seedConfig
const {
  admin: adminAccount,
  vendedor: vendedorAccount,
  computadora: computadoraAccount
} = cuentas

const seedDatabase = async () => {
  const hashedAdminPassword = await BcryptAdapter.hash(adminAccount.clave)
  const hashedVendedorPassword = await BcryptAdapter.hash(vendedorAccount.clave)
  const hashedComputadoraPassword = await BcryptAdapter.hash(
    computadoraAccount.clave
  )
  const adminSecret = JwtAdapter.randomSecret()
  const vendedorSecret = JwtAdapter.randomSecret()
  const computadoraSecret = JwtAdapter.randomSecret()

  const sucursales = await db
    .insert(schema.sucursalesTable)
    .values(sucursalesValues)
    .returning({ id: schema.sucursalesTable.id })

  const empleadosValues = Array.from({ length: seedConfig.empleadosCount }).map(
    (_, i) => {
      const [fechaString] = faker.date.recent().toISOString().split('T')
      const baseValues = {
        edad: faker.number.int({ min: 18, max: 60 }),
        dni:
          faker.number.int({ min: 1111111, max: 9999999 }).toString() +
          i.toString(),
        horaInicioJornada: '08:00:00',
        horaFinJornada: '17:00:00',
        fechaContratacion: fechaString
      }

      if (i === 0) {
        const [sucursal] = sucursales
        return {
          nombre: 'Administrador',
          apellidos: 'Principal',
          sucursalId: sucursal.id,
          ...baseValues
        }
      }

      return {
        nombre: faker.person.firstName(),
        apellidos: faker.person.lastName(),
        sucursalId: getRandomValueFromArray(sucursales).id,
        ...baseValues
      }
    }
  )

  const [admin, vendedorEmpleado, computadoraEmpleado] = await db
    .insert(schema.empleadosTable)
    .values(empleadosValues)
    .returning({ id: schema.empleadosTable.id })

  const [adminRole, vendedorRole, computadoraRole] = await db
    .insert(schema.rolesCuentasEmpleadosTable)
    .values(rolesValues)
    .returning({ id: schema.rolesCuentasEmpleadosTable.id })

  const permisos = await db
    .insert(schema.permisosTable)
    .values(adminPermissions)
    .returning({
      id: schema.permisosTable.id,
      codigoPermiso: schema.permisosTable.codigoPermiso
    })

  const permisosVendedorId = permisos.filter((permiso) =>
    vendedorPermisssions.some(
      (vendedorPermiso) =>
        vendedorPermiso.codigoPermiso === permiso.codigoPermiso
    )
  )

  const permisosComputadoraId = permisos.filter((permiso) =>
    computadoraPermissions.some(
      (computadoraPermiso) =>
        computadoraPermiso.codigoPermiso === permiso.codigoPermiso
    )
  )

  await db.insert(schema.rolesPermisosTable).values([
    ...permisos.map((permiso) => ({
      permisoId: permiso.id,
      rolId: adminRole.id
    })),
    ...permisosVendedorId.map((permiso) => ({
      permisoId: permiso.id,
      rolId: vendedorRole.id
    })),
    ...permisosComputadoraId.map((permiso) => ({
      permisoId: permiso.id,
      rolId: computadoraRole.id
    }))
  ])

  await db.insert(schema.cuentasEmpleadosTable).values([
    {
      usuario: adminAccount.usuario,
      clave: hashedAdminPassword,
      secret: adminSecret,
      rolCuentaEmpleadoId: adminRole.id,
      empleadoId: admin.id
    },
    {
      usuario: vendedorAccount.usuario,
      clave: hashedVendedorPassword,
      secret: vendedorSecret,
      rolCuentaEmpleadoId: vendedorRole.id,
      empleadoId: vendedorEmpleado.id
    },
    {
      usuario: computadoraAccount.usuario,
      clave: hashedComputadoraPassword,
      secret: computadoraSecret,
      rolCuentaEmpleadoId: computadoraRole.id,
      empleadoId: computadoraEmpleado.id
    }
  ])

  const categorias = await db
    .insert(schema.categoriasTable)
    .values(categoriasValues)
    .returning({ id: schema.categoriasTable.id })

  const marcas = await db
    .insert(schema.marcasTable)
    .values(marcasValues)
    .returning({ id: schema.marcasTable.id })

  const colores = await db
    .insert(schema.coloresTable)
    .values(coloresValues)
    .returning({ id: schema.coloresTable.id })

  const productosValues = Array.from({ length: seedConfig.productosCount }).map(
    (_, i) => ({
      // sku: faker.string.alphanumeric(11) + i.toString(),
      nombre: faker.commerce.productName() + i.toString(),
      descripcion: faker.commerce.productDescription(),
      maxDiasSinReabastecer: faker.number.int({ min: 20, max: 90 }),
      stockMinimo: faker.number.int({ min: 20, max: 30 }),
      cantidadMinimaDescuento: faker.number.int({ min: 2, max: 5 }),
      cantidadGratisDescuento: faker.number.int({ min: 1, max: 2 }),
      porcentajeDescuento: faker.number.int({ min: 10, max: 20 }),
      colorId: getRandomValueFromArray(colores).id,
      categoriaId: getRandomValueFromArray(categorias).id,
      marcaId: getRandomValueFromArray(marcas).id
    })
  )

  const productos = await db
    .insert(schema.productosTable)
    .values(productosValues)
    .returning({
      id: schema.productosTable.id,
      stockMinimo: schema.productosTable.stockMinimo
    })

  const detallesProductosValues = productos.flatMap((producto) =>
    sucursales.flatMap((sucursal) => {
      const stock = faker.number.int({ min: 10, max: 200 })
      return {
        precioCompra: faker.commerce.price({ min: 160, max: 200 }),
        precioVenta: faker.commerce.price({ min: 150, max: 180 }),
        precioOferta: faker.commerce.price({ min: 155, max: 180 }),
        stock,
        stockBajo:
          producto.stockMinimo !== null ? stock < producto.stockMinimo : false,
        productoId: producto.id,
        sucursalId: sucursal.id
      }
    })
  )

  await db.insert(schema.detallesProductoTable).values(detallesProductosValues)

  const fotosProductosValues = productos.map((producto) => ({
    path: `static/img/${faker.string.alphanumeric(10)}/${faker.string.alphanumeric(5)}.jpg`,
    productoId: producto.id
  }))

  await db.insert(schema.fotosProductosTable).values(fotosProductosValues)

  await db
    .insert(schema.estadosTransferenciasInventarios)
    .values(estadosTransferenciasInventariosValues)

  await db.insert(schema.tiposPersonasTable).values(tiposPersonasValues)
}

const { NODE_ENV: nodeEnv } = envs

if (!isProduction) {
  if (seedConfig.empleadosCount < 3) {
    throw new Error('La cantidad de empleados configurada debe ser al menos 3')
  }

  seedDatabase()
    .then(() => {
      console.log('Database has been seeded correctly!')
      console.log('users credentials:', seedConfig.cuentas)
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
