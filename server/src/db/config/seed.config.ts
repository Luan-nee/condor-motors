import { envs } from '@/config/envs'
import { permissionCodes } from '@/consts'
import {
  transformPermissionsCodesFromArray,
  transformPermissionCodes
} from '@/core/lib/utils'

// El primer rol siempre será tratado como administrador y tendrá todos los permisos
export const seedConfig: SeedConfig = {
  cuentas: {
    admin: {
      usuario: envs.ADMIN_USER,
      clave: envs.ADMIN_PASSWORD
    },
    vendedor: {
      usuario: 'Vendedor',
      clave: 'Vende123'
    },
    computadora: {
      usuario: 'Computadora',
      clave: 'Compu123'
    }
  },
  rolesDefault: ['Adminstrador', 'Vendedor', 'Computadora'],
  categoriasDefault: [
    'No especificada',
    'Cascos',
    'Stickers',
    'Motos',
    'Toritos'
  ],
  marcasDefault: ['Sin marca', 'Genérico', 'Honda', 'Suzuki', 'Bajaj'],
  coloresDefault: [
    'No definido',
    'Negro',
    'Amarillo',
    'Rojo',
    'Verde',
    'Naranja',
    'Morado'
  ],
  estadosTransferenciasInventariosDefault: [
    'Pendiente',
    'Solicitando',
    'Rechazado',
    'Completado'
  ],
  tiposPersonasDefault: ['Persona Natural', 'Persona Juridica'],
  sucursalesCount: 3,
  empleadosCount: 6,
  productosCount: 15
}

export const adminPermissions = transformPermissionCodes(permissionCodes)

export const vendedorPermisssions = transformPermissionsCodesFromArray([
  permissionCodes.sucursales.getRelated,
  permissionCodes.empleados.getRelated,
  permissionCodes.productos.createRelated,
  permissionCodes.productos.getRelated,
  permissionCodes.productos.updateRelated,
  permissionCodes.inventarios.addRelated,
  permissionCodes.ventas.createRelated,
  permissionCodes.ventas.getRelated,
  permissionCodes.cuentasEmpleados.getRelated,
  permissionCodes.cuentasEmpleados.updateSelf
])

export const computadoraPermissions = transformPermissionsCodesFromArray([
  permissionCodes.sucursales.getRelated,
  permissionCodes.empleados.getRelated,
  permissionCodes.productos.getRelated,
  permissionCodes.ventas.getRelated,
  permissionCodes.cuentasEmpleados.getRelated,
  permissionCodes.categorias.createAny
])
