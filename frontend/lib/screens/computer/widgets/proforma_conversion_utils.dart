import 'dart:async';
import 'dart:convert';

import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:condorsmotors/main.dart' show api; // Importar la API global

/// Clase para gestionar la conversión de proformas a ventas
class ProformaConversionManager {
  /// Convierte una proforma a venta con manejo de errores
  ///
  /// [context] Contexto para mostrar mensajes
  /// [proforma] Proforma a convertir
  /// [tipoDocumento] Tipo de documento (BOLETA/FACTURA)
  /// [onSuccess] Callback ejecutado al completar la conversión exitosamente
  ///
  /// Retorna true si la conversión fue exitosa, false en caso contrario
  static Future<bool> convertirProformaAVenta({
    required BuildContext context,
    required Proforma proforma,
    required String tipoDocumento,
    required VoidCallback onSuccess,
  }) async {
    // Verificar permisos para evitar errores 403
    final bool tienePermisos = await _verificarPermisos();
    if (!tienePermisos) {
      if (context.mounted) {
        _cerrarDialogoProcesamiento(context);
        _mostrarErrorPermisos(context);
      }
      return false;
    }
    
    // Mostrar diálogo de procesamiento
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => _buildProcessingDialog(tipoDocumento.toLowerCase()),
      );
    }
    
    try {
      // Establecer un timeout global para toda la operación
      final result = await _convertirConTimeout(proforma.id, tipoDocumento);
      
      // Cerrar diálogo de procesamiento
      if (context.mounted) {
        _cerrarDialogoProcesamiento(context);
      }
      
      if (result != null) {
        // Mostrar mensaje de éxito
        if (context.mounted) {
          _mostrarExito(context, result);
        }
        
        // Ejecutar callback de éxito
        onSuccess();
        return true;
      } else {
        // Verificar si la proforma ya fue convertida a pesar del error
        final bool fueConvertida = await _verificarConversion(proforma.id);
        
        if (fueConvertida) {
          // Si la proforma fue convertida a pesar del error, mostrar éxito
          if (context.mounted) {
            _mostrarExito(context, 'La proforma se convirtió correctamente a venta.');
          }
          onSuccess();
          return true;
        } else {
          // Mostrar error genérico
          if (context.mounted) {
            _mostrarError(context, 'No se pudo convertir la proforma a venta.');
          }
          return false;
        }
      }
    } catch (e) {
      Logger.error('Error al convertir proforma a venta: $e');
      
      // Cerrar diálogo de procesamiento
      if (context.mounted) {
        _cerrarDialogoProcesamiento(context);
      }
      
      // Verificar si la proforma ya fue convertida a pesar del error
      final bool fueConvertida = await _verificarConversion(proforma.id);
      
      if (fueConvertida) {
        // Si la proforma fue convertida a pesar del error, mostrar éxito
        if (context.mounted) {
          _mostrarExito(context, 'La proforma se convirtió correctamente a venta.');
        }
        onSuccess();
        return true;
      }
      
      // Determinar tipo de error para mensaje personalizado
      if (e is TimeoutException) {
        if (context.mounted) {
          _mostrarError(context, 'La operación ha excedido el tiempo límite. '
              'Verifique si la proforma fue convertida.');
        }
      } else {
        if (context.mounted) {
          _mostrarError(context, 'Error al convertir la proforma: ${e.toString()}');
        }
      }
      
      return false;
    }
  }
  
  /// Método alternativo para convertir proformas a ventas
  static Future<bool> convertirProformaAVentaAlternativa({
    required BuildContext context,
    required String sucursalId,
    required int proformaId,
    required String tipoDocumento,
    required VoidCallback onSuccess,
  }) async {
    try {
      Logger.debug('Intentando método alternativo de conversión: '
          'ProformaID: $proformaId, Tipo: $tipoDocumento');
      
      // Obtener la proforma primero
      final proformaResponse = await api.proformas.getProformaVenta(
        sucursalId: sucursalId,
        proformaId: proformaId,
      );
      
      if (proformaResponse.isEmpty) {
        if (context.mounted) {
          _mostrarError(context, 'No se pudo obtener la información de la proforma.');
          _cerrarDialogoProcesamiento(context);
        }
        return false;
      }
      
      final proformaData = proformaResponse['data'] ?? {};
      final detalles = proformaData['detalles'] ?? [];
      
      // Crear venta a partir de los datos de la proforma
      final Map<String, dynamic> ventaData = {
        'observaciones': 'Convertida desde Proforma #$proformaId',
        'tipoDocumentoId': tipoDocumento == 'BOLETA' ? 1 : 2,
        'monedaId': 1, // PEN por defecto
        'metodoPagoId': 1, // Efectivo por defecto
        'clienteId': proformaData['clienteId'],
        'detalles': detalles,
      };
      
      // Crear la venta usando la API estándar de ventas
      final response = await api.ventas.createVenta(ventaData, sucursalId: sucursalId);
      
      // Cerrar diálogo de procesamiento
      if (context.mounted) {
        _cerrarDialogoProcesamiento(context);
      }
      
      if (response['status'] == 'success') {
        final String numeroDoc = response['data']?['numeroDocumento'] ?? '';
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
        return true;
      } else {
        if (context.mounted) {
          _mostrarError(context, 'No se pudo crear la venta: ${response?['message'] ?? 'Error desconocido'}');
        }
        return false;
      }
    } catch (e) {
      Logger.error('Error en conversión alternativa: $e');
      if (context.mounted) {
        _cerrarDialogoProcesamiento(context);
        _mostrarError(context, 'Error en la conversión alternativa: ${e.toString()}');
      }
      return false;
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
  
  /// Convierte una proforma a venta con un timeout global
  static Future<String?> _convertirConTimeout(int proformaId, String tipoDocumento) async {
    try {
      // Obtener el ID de sucursal del usuario
      final userData = await api.authService.getUserData();
      if (userData == null || !userData.containsKey('sucursalId')) {
        throw Exception('No se pudo obtener el ID de sucursal del usuario');
      }
      
      final String sucursalId = userData['sucursalId'].toString();
      
      // Crear datos básicos para la conversión
      final Map<String, dynamic> datosVenta = {
        'tipoDocumento': tipoDocumento,
      };
      
      // Establecer un timeout global de 15 segundos
      final response = await api.proformas.convertirProformaAVenta(
        sucursalId: sucursalId,
        proformaId: proformaId,
        datosVenta: datosVenta,
      ).timeout(const Duration(seconds: 15));
      
      // Verificar si la respuesta está vacía
      if (response.isEmpty) {
        Logger.warn('Respuesta vacía al convertir proforma $proformaId');
        return null;
      }
      
      // Simplificamos el manejo de la respuesta, asumiendo que siempre es un Map
      // Esto evita problemas de tipos con json.decode
      try {
        // Si la respuesta tiene un indicador de éxito, consideramos que fue exitosa
        if (response.containsKey('status') && response['status'] == 'success') {
          return 'Proforma convertida a venta correctamente.';
        } else if (response.containsKey('success') && response['success'] == true) {
          return 'Proforma convertida a venta correctamente.';
        } else {
          // No encontramos indicador de éxito, pero podemos verificar la conversión después
          return null;
        }
      } catch (e) {
        Logger.error('Error al procesar respuesta: $e');
        return null;
      }
    } on TimeoutException {
      Logger.warn('Timeout al convertir proforma $proformaId');
      throw TimeoutException('La operación ha excedido el tiempo límite');
    } catch (e) {
      Logger.error('Error inesperado: $e');
      rethrow;
    }
  }
  
  /// Verifica si el usuario tiene permisos para convertir proformas
  static Future<bool> _verificarPermisos() async {
    // TODO: Implementar verificación de permisos
    // Por ahora asumimos que tiene permisos
    return true;
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
  
  /// Muestra un mensaje de error de permisos
  static void _mostrarErrorPermisos(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No tiene permisos para realizar esta operación.'),
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
} 