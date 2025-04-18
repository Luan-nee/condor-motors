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
  transformPermissionCodes,
  transformPermissionsCodesFromArray
} from '@/core/lib/utils'

export const populateConfig: PopulateConfig = {
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
    apellidos: 'Principal',
    activo: true
  },
  rolesDefault: ['Administrador', 'Vendedor', 'Computadora'],
  defaultCategoria: {
    nombre: 'No especificada',
    descripcion: 'Categoria por defecto del sistema'
  },
  defaultMarca: {
    nombre: 'Sin marca',
    descripcion: 'Marca por defecto del sistema'
  },
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
  ]
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
  permissionCodes.facturacion.declareRelated,
  permissionCodes.facturacion.syncRelated,
  permissionCodes.facturacion.cancelRelated,
  permissionCodes.cuentasEmpleados.getRelated,
  permissionCodes.cuentasEmpleados.updateSelf,
  permissionCodes.reservasProductos.createAny,
  permissionCodes.reservasProductos.updateAny,
  permissionCodes.reservasProductos.deleteAny,
  permissionCodes.transferenciasInvs.createRelated,
  permissionCodes.transferenciasInvs.sendRelated,
  permissionCodes.transferenciasInvs.cancelRelated,
  permissionCodes.transferenciasInvs.receiveRelated,
  permissionCodes.transferenciasInvs.getRelated,
  permissionCodes.transferenciasInvs.updateRelated,
  permissionCodes.transferenciasInvs.deleteRelated
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
  permissionCodes.ventas.cancelRelated,
  permissionCodes.facturacion.declareRelated,
  permissionCodes.facturacion.syncRelated,
  permissionCodes.facturacion.cancelRelated,
  permissionCodes.cuentasEmpleados.getRelated,
  permissionCodes.transferenciasInvs.createRelated,
  permissionCodes.transferenciasInvs.sendRelated,
  permissionCodes.transferenciasInvs.cancelRelated,
  permissionCodes.transferenciasInvs.receiveRelated,
  permissionCodes.transferenciasInvs.getRelated,
  permissionCodes.transferenciasInvs.updateRelated,
  permissionCodes.transferenciasInvs.deleteRelated
])
