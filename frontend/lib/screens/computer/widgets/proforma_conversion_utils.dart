import 'dart:async';

import 'package:condorsmotors/main.dart' show api; // Importar la API global
import 'package:condorsmotors/utils/logger.dart';
import 'package:flutter/material.dart';

/// Clase para gestionar la conversión de proformas a ventas
class ProformaConversionManager {
  /// Convierte una proforma a venta con manejo de errores
  ///
  /// [context] Contexto para mostrar mensajes
  /// [sucursalId] ID de la sucursal
  /// [proformaId] ID de la proforma a convertir
  /// [tipoDocumento] Tipo de documento (BOLETA/FACTURA)
  /// [onSuccess] Callback ejecutado al completar la conversión exitosamente
  ///
  /// Retorna true si la conversión fue exitosa, false en caso contrario
  static Future<bool> convertirProformaAVenta({
    required BuildContext context,
    required String sucursalId,
    required int proformaId,
    required String tipoDocumento,
    required VoidCallback onSuccess,
  }) async {
    try {
      Logger.debug('Convirtiendo proforma a venta: '
          'ProformaID: $proformaId, Tipo: $tipoDocumento');
      
      // Invalidar cache al inicio para asegurar que tenemos datos actualizados
      _recargarDatos(sucursalId);
      
      // Mostrar diálogo de procesamiento
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => _buildProcessingDialog(tipoDocumento.toLowerCase()),
        );
      }
      
      // Primero, verificar si la proforma existe sin usar caché para evitar problemas
      try {
        final proformaExistResponse = await api.proformas.getProformaVenta(
          sucursalId: sucursalId,
          proformaId: proformaId,
          useCache: false,
          forceRefresh: true,
        );
        
        // Verificar explícitamente si hay un error 404
        if (proformaExistResponse.isEmpty || 
            proformaExistResponse['status'] == 'fail' || 
            !proformaExistResponse.containsKey('data') || 
            proformaExistResponse['data'] == null) {
          
          // Cerrar diálogo de procesamiento
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            
            // Mensaje personalizado si es error 404
            if (proformaExistResponse.containsKey('error') && 
                proformaExistResponse['error'].toString().contains('Not found')) {
              _mostrarError(context, 'La proforma #$proformaId no existe o fue eliminada');
            } else {
              _mostrarError(context, 'No se pudo obtener información de la proforma');
            }
          }
          
          // Invalidar la caché completamente
          api.proformas.invalidateCache(sucursalId);
          // Forzar recarga de lista de proformas 
          _recargarProformasSucursal(sucursalId);
          
          return false;
        }
        
        // Si llegamos aquí, la proforma existe, obtenerla de nuevo para procesar sus datos
        final proformaResponse = await api.proformas.getProformaVenta(
          sucursalId: sucursalId,
          proformaId: proformaId,
        );
        
        // Verificar si el formato de datos es correcto
        if (!proformaResponse.containsKey('data') || proformaResponse['data'] == null) {
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(context, 'Formato de datos de proforma inválido');
          }
          return false;
        }
        
        final proformaData = proformaResponse['data'];
        final List<dynamic> detalles = proformaData['detalles'] ?? [];
        
        // Verificar si hay detalles en la proforma
        if (detalles.isEmpty) {
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(context, 'La proforma no tiene productos, no se puede convertir a venta');
          }
          return false;
        }
        
        // Verificar si hay cliente
        final dynamic clienteId = proformaData['clienteId'];
        if (clienteId == null) {
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(context, 'La proforma no tiene un cliente asignado');
          }
          return false;
        }
        
        // Crear venta a partir de los datos de la proforma
        final Map<String, dynamic> ventaData = {
          'observaciones': 'Convertida desde Proforma #$proformaId',
          'tipoDocumentoId': tipoDocumento == 'BOLETA' ? 1 : 2,
          'monedaId': 1, // PEN por defecto
          'metodoPagoId': 1, // Efectivo por defecto
          'clienteId': int.tryParse(clienteId.toString()) ?? 0,
          'detalles': detalles,
        };
        
        // Obtener el ID del empleado actual
        final userData = await api.authService.getUserData();
        if (userData != null && userData.containsKey('id')) {
          ventaData['empleadoId'] = int.tryParse(userData['id'].toString()) ?? 0;
        }
        
        Logger.debug('Preparando datos para crear venta: $ventaData');
        
        // Crear la venta usando la API estándar de ventas
        final Map<String, dynamic> ventaResponse = await api.ventas.createVenta(
          ventaData,
          sucursalId: sucursalId,
        );
        
        // Cerrar diálogo de procesamiento
        if (context.mounted) {
          _cerrarDialogoProcesamiento(context);
        }
        
        if (ventaResponse['status'] != 'success') {
          final String errorMsg = ventaResponse.containsKey('error') 
              ? ventaResponse['error'].toString() 
              : ventaResponse['message'] ?? 'Error desconocido';
          
          Logger.error('Error al crear venta: $errorMsg');
          
          if (context.mounted) {
            _mostrarError(context, 'No se pudo crear la venta: $errorMsg');
          }
          return false;
        }
        
        final String numeroDoc = ventaResponse['data']?['numeroDocumento'] ?? '';
        if (context.mounted) {
          _mostrarExito(context, 'Venta creada correctamente: $numeroDoc');
        }
        
        // Marcar la proforma como convertida (actualizar estado)
        await api.proformas.updateProformaVenta(
          sucursalId: sucursalId,
          proformaId: proformaId,
          estado: 'convertida',
        );
        
        // Ejecutar callback de éxito
        onSuccess();
        
        // Forzar recarga de proformas para actualizar UI
        _recargarProformasSucursal(sucursalId);
        
        return true;
        
      } catch (apiError) {
        // Manejar específicamente el caso donde la proforma no existe (404)
        if (apiError.toString().contains('404') || 
            apiError.toString().contains('Not found')) {
          
          // Invalidar caché
          api.proformas.invalidateCache(sucursalId);
          _recargarProformasSucursal(sucursalId);
          
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(context, 'La proforma #$proformaId no existe o fue eliminada');
          }
          return false;
        }
        
        // Otros errores de API
        Logger.error('Error en petición API: $apiError');
        if (context.mounted) {
          _cerrarDialogoProcesamiento(context);
          _mostrarError(context, 'Error en la conversión: ${apiError.toString()}');
        }
        return false;
      }
    } catch (e) {
      Logger.error('Error en conversión de proforma: $e');
      if (context.mounted) {
        _cerrarDialogoProcesamiento(context);
        _mostrarError(context, 'Error en la conversión: ${e.toString()}');
      }
      return false;
    }
  }
  
  /// Recarga los datos de proformas y sucursales para asegurar sincronización
  static Future<void> _recargarDatos(String sucursalId) async {
    try {
      // Invalidar caché de proformas para la sucursal específica
      api.proformas.invalidateCache(sucursalId);
      Logger.debug('Caché de proformas invalidado para sucursal $sucursalId');
      
      // Recargar datos de la sucursal para mantener coherencia
      await api.sucursales.getSucursalData(sucursalId, forceRefresh: true);
      Logger.debug('Datos de sucursal recargados: $sucursalId');
      
      // Recargar proformas específicas para esta sucursal
      await api.proformas.getProformasVenta(
        sucursalId: sucursalId,
        useCache: false,
        forceRefresh: true,
      );
      Logger.debug('Lista de proformas recargada para sucursal $sucursalId');
    } catch (e) {
      Logger.error('Error al recargar datos: $e');
      // No propagamos el error para no interrumpir el flujo principal
    }
  }
  
  /// Verifica si la proforma ya fue convertida (útil para casos donde el API falla pero la conversión fue exitosa)
  static Future<bool> _verificarConversion(int proformaId) async {
    try {
      // Obtener el ID de sucursal del usuario
      final userData = await api.authService.getUserData();
      if (userData == null || !userData.containsKey('sucursalId')) {
        return false;
      }
      
      final String sucursalId = userData['sucursalId'].toString();
      
      // Verificar estado de la proforma
      final response = await api.proformas.getProformaVenta(
        sucursalId: sucursalId,
        proformaId: proformaId,
        forceRefresh: true,
      );
      
      if (response.isNotEmpty && response['data'] != null) {
        final String estado = response['data']['estado'] ?? '';
        return estado.toLowerCase() == 'convertida';
      }
      return false;
    } catch (e) {
      Logger.error('Error al verificar conversión: $e');
      return false;
    }
  }
  
  
  /// Cierra el diálogo de procesamiento
  static void _cerrarDialogoProcesamiento(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
  
  /// Muestra un mensaje de éxito
  static void _mostrarExito(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Muestra un mensaje de error
  static void _mostrarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  
  /// Construye el diálogo de procesamiento
  static Widget _buildProcessingDialog(String tipoDocumento) {
    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Procesando ${tipoDocumento.toLowerCase()}...',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Por favor espere',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Recarga la lista de proformas de una sucursal para mantener datos actualizados
  static Future<void> _recargarProformasSucursal(String sucursalId) async {
    try {
      // Invalidar caché de proformas
      api.proformas.invalidateCache(sucursalId);
      // Invalidar caché de la sucursal
      api.sucursales.invalidateCache(sucursalId);
      
      // Forzar recarga de la lista de proformas
      await api.proformas.getProformasVenta(
        sucursalId: sucursalId,
        useCache: false,
        forceRefresh: true,
      );
      
      // También recargar desde la API de sucursales para mantener sincronización
      await api.sucursales.getProformasVenta(
        sucursalId,
        useCache: false,
        forceRefresh: true,
      );
      
      Logger.debug('Lista de proformas recargada para sucursal $sucursalId');
    } catch (e) {
      Logger.error('Error al recargar lista de proformas: $e');
    }
  }
} 