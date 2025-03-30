import { envs } from '@/config/envs'
import {
  estadosDocFacturacion,
  estadosTransferenciasInvCodes,
  permissionCodes,
  tiposDocClienteCodes,
  tiposDocFacturacionCodes,
  tiposTaxCodes
} from '@/consts'
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
  rolesDefault: ['Administrador', 'Vendedor', 'Computadora'],
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
  estadosTransferenciasInvDefault: [
    {
      nombre: 'Pedido',
      codigo: estadosTransferenciasInvCodes.pedido
    },
    {
      nombre: 'Enviado',
      codigo: estadosTransferenciasInvCodes.enviado
    },
    {
      nombre: 'Recibido',
      codigo: estadosTransferenciasInvCodes.recibido
    }
  ],
  tiposDocumentoClienteDefault: [
    {
      nombre: 'RUC',
      codigoSunat: '6',
      codigo: tiposDocClienteCodes.ruc
    },
    {
      nombre: 'DNI',
      codigoSunat: '1',
      codigo: tiposDocClienteCodes.dni
    },
    {
      nombre: 'CARNET DE EXTRANJERÍA',
      codigoSunat: '4',
      codigo: tiposDocClienteCodes.carnetExtranjeria
    },
    {
      nombre: 'PASAPORTE',
      codigoSunat: '7',
      codigo: tiposDocClienteCodes.pasaporte
    },
    {
      nombre: 'CÉDULA DIPLOMÁTICA DE IDENTIDAD',
      codigoSunat: 'A',
      codigo: tiposDocClienteCodes.cedulaDiplomáticaIdentidad
    },
    {
      nombre: 'NO DOMICILIADO, SIN RUC',
      codigoSunat: '0',
      codigo: tiposDocClienteCodes.noDomiciliadoSinRuc
    }
  ],
  tiposDocumentoFacturacionDefault: [
    {
      nombre: 'Factura electrónica',
      codigoSunat: '01',
      codigo: tiposDocFacturacionCodes.factura
    },
    {
      nombre: 'Boleta de venta electrónica',
      codigoSunat: '03',
      codigo: tiposDocFacturacionCodes.boleta
    }
  ],
  monedasFacturacionDefault: [{ nombre: 'Soles', codigoSunat: 'PEN' }],
  metodosPagoDefault: [
    {
      nombre: 'Contado',
      codigoSunat: 'Contado',
      codigoTipo: '0',
      activado: true
    }
  ],
  tiposTaxDefault: [
    {
      nombre: 'Gravado (Con 18% de impuestos)',
      codigoSunat: '10',
      porcentaje: 18,
      codigo: tiposTaxCodes.gravado
    },
    {
      nombre: 'Exonerado (Sin impuestos)',
      codigoSunat: '20',
      porcentaje: 0,
      codigo: tiposTaxCodes.exonerado
    },
    {
      nombre: 'Gratuito (Producto gratuito)',
      codigoSunat: '21',
      porcentaje: 0,
      codigo: tiposTaxCodes.gratuito
    }
  ],
  estadosDocFacturacion: [
    {
      nombre: 'Registrado en el servicio de facturacion',
      codigoSunat: '01',
      codigo: estadosDocFacturacion.registrado
    },
    {
      nombre: 'Enviado pero sin respuesta de la sunat',
      codigoSunat: '03',
      codigo: estadosDocFacturacion.enviadoSinRespuesta
    },
    {
      nombre: 'Aceptado ante la sunat',
      codigoSunat: '05',
      codigo: estadosDocFacturacion.aceptadoSunat
    },
    {
      nombre: 'Rechazado ante la sunat',
      codigoSunat: '09',
      codigo: estadosDocFacturacion.rechazadoSunat
    },
    {
      nombre: 'Anulado ante la sunat',
      codigoSunat: '11',
      codigo: estadosDocFacturacion.anuladoSunat
    },
    {
      nombre: 'Por anular ',
      codigoSunat: '13',
      codigo: estadosDocFacturacion.porAnular
    },
    {
      nombre: 'Sin respuesta de la sunat',
      codigoSunat: '19',
      codigo: estadosDocFacturacion.sinRespuestaSunat
    }
  ],
  sucursalesCount: 3,
  empleadosCount: 9,
  productosCount: 30,
  proformasVentaCount: 16,
  notificacionesCount: 5,
  clientesCount: 5
}

export const adminPermissions = transformPermissionCodes(permissionCodes)

export const vendedorPermisssions = transformPermissionsCodesFromArray([
  permissionCodes.sucursales.getRelated,
  permissionCodes.empleados.getRelated,
  permissionCodes.productos.createRelated,
  permissionCodes.productos.getRelated,
  permissionCodes.proformasVenta.createRelated,
  permissionCodes.proformasVenta.getRelated,
  permissionCodes.proformasVenta.updateRelated,
  permissionCodes.proformasVenta.deleteRelated,
  permissionCodes.ventas.createRelated,
  permissionCodes.ventas.getRelated,
  permissionCodes.ventas.cancelRelated,
  permissionCodes.cuentasEmpleados.getRelated,
  permissionCodes.cuentasEmpleados.updateSelf,
  permissionCodes.reservasProductos.createAny,
  permissionCodes.reservasProductos.updateAny,
  permissionCodes.reservasProductos.deleteAny
])

export const computadoraPermissions = transformPermissionsCodesFromArray([
  permissionCodes.sucursales.getRelated,
  permissionCodes.empleados.getRelated,
  permissionCodes.productos.getRelated,
  permissionCodes.proformasVenta.createRelated,
  permissionCodes.proformasVenta.getRelated,
  permissionCodes.proformasVenta.updateRelated,
  permissionCodes.proformasVenta.deleteRelated,
  permissionCodes.ventas.createRelated,
  permissionCodes.ventas.getRelated,
  permissionCodes.cuentasEmpleados.getRelated
])
