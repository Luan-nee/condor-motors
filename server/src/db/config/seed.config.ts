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
    { nombre: 'No definido', hex: '#FFFFFF' },
    { nombre: 'Negro', hex: '#000000' },
    { nombre: 'Amarillo', hex: '#FFFF00' },
    { nombre: 'Rojo', hex: '#FF0000' },
    { nombre: 'Verde', hex: '#008000' },
    { nombre: 'Naranja', hex: '#FFA500' },
    { nombre: 'Morado', hex: '#800080' }
  ],
  estadosTransferenciasInventariosDefault: [
    'Pendiente',
    'Solicitando',
    'Rechazado',
    'Completado'
  ],
  tiposDocumentoFacturacionDefault: [
    { nombre: 'Factura electrónica', codigo: '01' },
    { nombre: 'Boleta de venta electrónica', codigo: '03' }
  ],
  monedasFacturacionDefault: [{ nombre: 'Soles', codigo: 'PEN' }],
  metodosPagoDefault: [
    {
      nombre: 'Contado',
      codigo: 'Contado',
      tipo: '0',
      activado: true
    },
    {
      nombre: 'Crédito',
      codigo: 'Crédito',
      tipo: '1',
      activado: false
    }
  ],
  tiposTaxDefault: [
    { nombre: 'Pagar impuestos', codigo: '10' },
    { nombre: 'Evadir impuestos 💵🤑💸', codigo: '20' }
  ],
  sucursalesCount: 3,
  empleadosCount: 9,
  productosCount: 30,
  proformasVentaCount: 16,
  notificacionesCount: 5
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
